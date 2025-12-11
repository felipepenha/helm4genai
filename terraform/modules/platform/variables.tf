variable "vela_replica_count" {
  description = "Number of replicas for KubeVela controller"
  type        = number
  default     = 1
}

variable "genai_enabled" {
  description = "Enable GenAI stack (vLLM, Langfuse, MCP)"
  type        = bool
  default     = true
}
