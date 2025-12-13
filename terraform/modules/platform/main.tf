





resource "helm_release" "mcp" {
  count            = var.genai_enabled ? 1 : 0
  name             = "mcp"
  chart            = "${path.module}/charts/mcp"
  namespace        = "genai"
  create_namespace = true
  wait             = false

  values = [
    yamlencode({
      image = {
        repository = var.mcp_image_repository != "" ? var.mcp_image_repository : "localhost/mcp/server"
        tag        = var.mcp_image_tag != "" ? var.mcp_image_tag : "latest"
      }
    })
  ]
}
