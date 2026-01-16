variable "name_prefix" {
  description = "Prefix for generated instance names"
  type        = string
  default     = "mc-java"
}

variable "docker_image" {
  description = "Docker image for the Java edition"
  type        = string
  default     = "itzg/minecraft-server:latest"
}
