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

variable "langfuse_nextauth_url" {
  description = "The NextAuth URL for Langfuse (e.g. http://localhost:3000 for local, https://langfuse.example.com for prod)"
  type        = string
  default     = "http://localhost:3000"
}

variable "langfuse_nextauth_secret" {
  description = "The NextAuth secret for Langfuse"
  type        = string
  default     = "super-secret-nextauth-secret"
  sensitive   = true
}

variable "langfuse_salt" {
  description = "The salt for Langfuse"
  type        = string
  default     = "super-secret-salt-value-change-me"
  sensitive   = true
}

variable "langfuse_db_password" {
  description = "Password for the Postgres/Clickhouse database"
  type        = string
  sensitive   = true
  default     = "postgres-password"
}

variable "clickhouse_replica_count" {
  description = "Number of Clickhouse replicas"
  type        = number
  default     = 1
}

variable "clickhouse_resources" {
  description = "Resource limits and requests for Clickhouse"
  type = object({
    limits = object({
      memory = string
    })
    requests = object({
      memory = string
    })
  })
  default = {
    limits = {
      memory = "4Gi"
    }
    requests = {
      memory = "512Mi"
    }
  }
}

variable "clickhouse_background_pool_size" {
  description = "Size of the Clickhouse background schedule pool"
  type        = number
  default     = 16
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
