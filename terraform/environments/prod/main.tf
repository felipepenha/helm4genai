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
  deletion_protection        = false

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-standard-2" # Sufficient for system components and simple workloads
      node_locations            = var.zone
      min_count                 = 1
      max_count                 = 2
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
    {
      name                      = "gpu-pool"
      machine_type              = "g2-standard-8" # Includes 1x NVIDIA L4 GPU (24GB VRAM)
      node_locations            = var.zone
      min_count                 = 0
      max_count                 = 3
      local_ssd_count           = 0
      spot                      = true # Significant cost savings (~60-91%)
      disk_size_gb              = 100
      disk_type                 = "pd-ssd"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = true
      auto_repair               = true
      auto_upgrade              = true
      service_account           = "default"
      preemptible               = false
      initial_node_count        = 0 # Autoscaling will kick in when needed
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
  genai_enabled            = true
  
  mcp_image_repository     = var.mcp_image_repository
  mcp_image_tag            = var.mcp_image_tag
  
  depends_on = [module.gke]

  # Production vLLM Configuration
  vllm_image             = "vllm/vllm-openai:latest"
  vllm_image_pull_policy = "IfNotPresent"
  vllm_env = {
    VLLM_TARGET_DEVICE = "gpu"
  }
  # Assuming GPU nodes are available in prod (L4 24GB)
  vllm_args = [
    "--model", "TheBloke/Llama-2-13B-chat-GPTQ", # Example fitting on single L4
    "--quantization", "gptq",
    "--max-model-len", "4096",
    "--gpu-memory-utilization", "0.95"
  ]
  vllm_resources = {
    limits = {
      memory = "28Gi"
      cpu    = "6"
      "nvidia.com/gpu" = "1"
    }
    requests = {
      memory = "16Gi"
      cpu    = "2"
      "nvidia.com/gpu" = "1"
    }
  }
}
