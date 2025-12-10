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
  
  # Ensure the cluster is ready before installing Helm charts
  depends_on = [kind_cluster.default]
  
  # Example of passing variables
  vela_replica_count = 1
}
