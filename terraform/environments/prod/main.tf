provider "google" {
  project = var.project_id
  region  = var.region
  # Credentials should be set via GOOGLE_APPLICATION_CREDENTIALS env var
  # or by running `gcloud auth application-default login`
}

# Official GKE Module
module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  version                    = "29.0.0"
  project_id                 = var.project_id
  name                       = "helm4genai-prod"
  region                     = var.region
  zones                      = [var.zone]
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-medium"
      node_locations            = var.zone
      min_count                 = 1
      max_count                 = 3
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 50
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = false
      auto_repair               = true
      auto_upgrade              = true
      service_account           = "default"
      preemptible               = false
      initial_node_count        = 1
    },
  ]
}

# Authenticate Helm/K8s providers with GKE
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

module "platform" {
  source = "../../modules/platform"
  
  # High Availability for Production
  vela_replica_count       = 3
  genai_enabled            = true
  langfuse_nextauth_url    = var.langfuse_nextauth_url
  langfuse_nextauth_secret = var.langfuse_nextauth_secret
  langfuse_salt            = var.langfuse_salt
  langfuse_db_password     = var.langfuse_db_password
  
  depends_on = [module.gke]

  # Production/HA Configuration
  clickhouse_replica_count        = 3
  clickhouse_background_pool_size = 512 # Default value
  clickhouse_resources = {
    limits = {
      memory = "12Gi"
    }
    requests = {
      memory = "4Gi"
    }
  }

  # Production vLLM Configuration
  vllm_image             = "vllm/vllm-openai:latest"
  vllm_image_pull_policy = "IfNotPresent"
  vllm_env = {
    VLLM_TARGET_DEVICE = "gpu"
  }
  # Assuming GPU nodes are available in prod for 120b model
  vllm_args = [
    "--model", "gpt-oss:120b",
    "--max-model-len", "4096",
    "--tensor-parallel-size", "2"
  ]
  vllm_resources = {
    limits = {
      memory = "64Gi"
      cpu    = "8"
      "nvidia.com/gpu" = "2"
    }
    requests = {
      memory = "32Gi"
      cpu    = "4"
      "nvidia.com/gpu" = "2"
    }
  }
}
