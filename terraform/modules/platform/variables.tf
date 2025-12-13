

variable "genai_enabled" {
  description = "Enable GenAI stack (vLLM, Langfuse, MCP)"
  type        = bool
  default     = true
}



# vLLM Configuration Variables
variable "vllm_image" {
  description = "The vLLM image to use"
  type        = string
  default     = "vllm/vllm-openai:latest"
}

variable "vllm_image_pull_policy" {
  description = "Image pull policy for vLLM"
  type        = string
  default     = "IfNotPresent"
}

variable "vllm_args" {
  description = "Arguments for the vLLM container"
  type        = list(string)
  default     = []
}

variable "vllm_env" {
  description = "Environment variables for vLLM"
  type        = map(string)
  default     = {}
}

variable "vllm_resources" {
  description = "Resource limits and requests for vLLM"
  type = object({
    limits = object({
      memory = string
      cpu    = string
    })
    requests = object({
      memory = string
      cpu    = string
    })
  })
  default = {
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

variable "mcp_image_repository" {
  description = "The repository for the MCP server image"
  type        = string
  default     = ""
}

variable "mcp_image_tag" {
  description = "The tag for the MCP server image"
  type        = string
  default     = ""
}
