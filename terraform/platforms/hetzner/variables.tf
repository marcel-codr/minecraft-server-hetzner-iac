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
    domain       = optional(string, "")
  }))
  default = []
}

variable "dns_zone" {
  description = "DNS zone name (e.g., example.com) - must be managed in Hetzner DNS"
  type        = string
  default     = ""
}


variable "ssh_keys" {
  description = "List of SSH key names to add to servers"
  type        = list(string)
  default     = []
}
