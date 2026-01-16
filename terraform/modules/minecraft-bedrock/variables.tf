variable "name_prefix" {
  description = "Prefix for generated instance names"
  type        = string
  default     = "mc-bedrock"
}

variable "docker_image" {
  description = "Docker image for the Bedrock/C++ edition"
  type        = string
  default     = "itzg/minecraft-bedrock-server:latest"
}
