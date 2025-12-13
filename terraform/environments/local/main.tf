provider "kind" {}

resource "kind_cluster" "default" {
  name = "helm4genai-cluster"
  wait_for_ready = true
}

provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}



module "platform" {
  source = "../../modules/platform"
  
  # Ensure images are loaded before installing Helm charts
  # depends_on = [null_resource.load_images]
  
  # Example of passing variables


  # Local Ollama Configuration
  vllm_image             = "ollama/ollama:latest"
  vllm_image_pull_policy = "IfNotPresent"
  vllm_env = {
    OLLAMA_HOST = "0.0.0.0:8000"
  }
  vllm_args = ["serve"]
  vllm_resources = {
    limits = {
      memory = "4Gi"
      cpu    = "2"
    }
    requests = {
      memory = "2Gi"
      cpu    = "1"
    }
  }
}
