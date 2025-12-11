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

resource "null_resource" "load_images" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = <<EOT
      # Helper function to load image safely
      load_image() {
        IMAGE=$1
        TAR_FILE="/tmp/$(basename $IMAGE | tr : _).tar"
        
        echo "Processing $IMAGE..."
        
        # Pull if missing locally (user must be logged in for rate-limited images)
        if ! podman image exists $IMAGE; then
          echo "Image $IMAGE not found locally. Attempting pull..."
          podman pull $IMAGE
        fi

        # Save to archive
        echo "Saving $IMAGE to $TAR_FILE..."
        podman save -o $TAR_FILE $IMAGE

        # Load into Kind
        echo "Loading $IMAGE into Kind cluster..."
        kind load image-archive $TAR_FILE --name helm4genai-cluster

        # Cleanup
        rm $TAR_FILE
      }

      load_image "docker.io/oamdev/vela-core:v1.9.13"
      load_image "docker.io/oamdev/cluster-gateway:v1.9.0-alpha.2"
      load_image "docker.io/oamdev/kube-webhook-certgen:v2.4.1"
      load_image "docker.io/oamdev/hello-world:latest"
    EOT
  }
}

module "platform" {
  source = "../../modules/platform"
  
  # Ensure images are loaded before installing Helm charts
  depends_on = [null_resource.load_images]
  
  # Example of passing variables
  vela_replica_count = 1
  genai_enabled      = true
}
