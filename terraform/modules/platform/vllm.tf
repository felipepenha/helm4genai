resource "kubernetes_deployment" "vllm" {
  count = var.genai_enabled ? 1 : 0

  depends_on = [helm_release.mcp]
  
  # Don't wait for rollout as the image might need to be loaded later (e.g. mock image)
  wait_for_rollout = false

  metadata {
    name      = "vllm"
    namespace = "genai"
    labels = {
      app = "vllm"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vllm"
      }
    }

    template {
      metadata {
        labels = {
          app = "vllm"
        }
      }

      spec {
        container {
          name  = "vllm"
          image = var.vllm_image

          # Environment variables from variable
          dynamic "env" {
            for_each = var.vllm_env
            content {
              name  = env.key
              value = env.value
            }
          }
          
          args              = var.vllm_args
          image_pull_policy = var.vllm_image_pull_policy

          port {
            container_port = 8000
          }

          resources {
            limits   = var.vllm_resources.limits
            requests = var.vllm_resources.requests
          }
          
          # Shared memory is often needed for vLLM/PyTorch
          volume_mount {
            name       = "shm"
            mount_path = "/dev/shm"
          }
        }

        volume {
          name = "shm"
          empty_dir {
            medium = "Memory"
          }
        }

        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "vllm" {
  count = var.genai_enabled ? 1 : 0

  depends_on = [helm_release.mcp]

  metadata {
    name      = "vllm"
    namespace = "genai"
  }

  spec {
    selector = {
      app = "vllm"
    }

    port {
      port        = 8000
      target_port = 8000
    }
  }
}
