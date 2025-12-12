variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "langfuse_nextauth_url" {
  description = "The NextAuth URL for Langfuse"
  type        = string
}

variable "langfuse_nextauth_secret" {
  description = "The NextAuth secret for Langfuse"
  type        = string
  sensitive   = true
}

variable "langfuse_salt" {
  description = "The salt for Langfuse"
  type        = string
  sensitive   = true
}

variable "langfuse_db_password" {
  description = "The database password for Langfuse"
  type        = string
  sensitive   = true
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
