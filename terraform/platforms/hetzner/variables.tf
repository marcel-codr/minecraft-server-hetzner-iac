variable "name_prefix" {
  type    = string
  default = "mc"
}

variable "servers" {
  description = "List of Minecraft servers to deploy"
  type = list(object({
    name         = string
    edition      = string
    docker_image = string
    server_type  = string
    location     = string
  }))
  default = []
}

variable "project_name" {
  description = "Name for the Hetzner project"
  type        = string
  default     = ""
}

variable "account_token" {
  description = "Account-level API token for project creation"
  type        = string
  default     = ""
}

variable "ssh_keys" {
  description = "List of SSH key names to add to servers"
  type        = list(string)
  default     = []
}
