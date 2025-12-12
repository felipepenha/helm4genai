resource "helm_release" "kubevela" {
  name       = "kubevela"
  repository = "https://kubevela.io/charts"
  chart      = "vela-core"
  version    = "1.9.13" # Pinning a stable version
  namespace  = "vela-system"
  create_namespace = true
  wait       = true

  values = [
    jsonencode({
      image = {
        pullPolicy = "IfNotPresent"
      }
    })
  ]

  # Example of using variables for future configuration
  # set {
  #   name  = "replicaCount"
  #   value = var.vela_replica_count
  # }
}

resource "helm_release" "langfuse" {
  count            = var.genai_enabled ? 1 : 0
  name             = "langfuse"
  repository       = "https://langfuse.github.io/langfuse-k8s"
  chart            = "langfuse"
  namespace        = "genai"
  create_namespace = true
  values = [
    yamlencode({
      langfuse = {
        salt = {
          value = var.langfuse_salt
        }
        nextauth = {
          secret = {
            value = var.langfuse_nextauth_secret
          }
          url = var.langfuse_nextauth_url
        }
      }
      postgresql = {
        auth = {
          password = var.langfuse_db_password
          postgresPassword = var.langfuse_db_password
        }
      }
      clickhouse = {
        auth = {
          password      = var.langfuse_db_password
          adminPassword = var.langfuse_db_password
        }
        replicaCount = var.clickhouse_replica_count
        files = {
          "config-custom.xml" = <<EOF
<clickhouse>
    <background_schedule_pool_size>${var.clickhouse_background_pool_size}</background_schedule_pool_size>
</clickhouse>
EOF
        }
        resources = var.clickhouse_resources
      }
    })
  ]
  wait = false
}



resource "helm_release" "mcp" {
  count            = var.genai_enabled ? 1 : 0
  name             = "mcp"
  chart            = "${path.module}/charts/mcp"
  namespace        = "genai"
  create_namespace = true
  wait             = false
}
