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
  description = "The database password for Langfuse (Postgres and Clickhouse)"
  type        = string
  default     = "postgres-password"
  sensitive   = true
}
