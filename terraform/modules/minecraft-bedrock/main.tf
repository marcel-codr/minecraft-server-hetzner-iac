locals {
  cloud_init = templatefile("${path.module}/cloud-init.tpl", {
    container_name = var.name_prefix
    docker_image   = var.docker_image
  })
}

output "cloud_init" {
  description = "Cloud-init payload for Bedrock edition"
  value       = local.cloud_init
}
