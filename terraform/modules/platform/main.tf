resource "helm_release" "kubevela" {
  name       = "kubevela"
  repository = "https://kubevela.io/charts"
  chart      = "vela-core"
  version    = "1.9.13" # Pinning a stable version
  namespace  = "vela-system"
  create_namespace = true

  # Example of using variables for future configuration
  # set {
  #   name  = "replicaCount"
  #   value = var.vela_replica_count
  # }
}
