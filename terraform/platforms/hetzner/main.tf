resource "hcloud_project" "minecraft" {
  name     = var.project_name != "" ? var.project_name : "${var.name_prefix}-project"
  provider = hcloud.account
}

locals {
  # Create a map of server configs for easier lookup
  server_configs = { for server in var.servers : server.name => server }
}

resource "hcloud_server" "minecraft_servers" {
  for_each = local.server_configs

  name        = "${var.name_prefix}-${each.value.name}"
  server_type = each.value.server_type
  image       = "ubuntu-22.04"
  location    = each.value.location
  user_data   = each.value.edition == "java" ? module.minecraft_java[each.key].cloud_init : module.minecraft_bedrock[each.key].cloud_init
  ssh_keys    = var.ssh_keys
  labels = {
    role        = "minecraft"
    server_name = each.value.name
    edition     = each.value.edition
  }
}

# Java servers
module "minecraft_java" {
  for_each = { for server in var.servers : server.name => server if server.edition == "java" }

  source       = "../../modules/minecraft-java"
  name_prefix  = each.value.name
  docker_image = each.value.docker_image
}

# Bedrock servers  
module "minecraft_bedrock" {
  for_each = { for server in var.servers : server.name => server if server.edition == "bedrock" }

  source       = "../../modules/minecraft-bedrock"
  name_prefix  = each.value.name
  docker_image = each.value.docker_image
}

output "ips" {
  value = [for s in hcloud_server.minecraft_servers : s.ipv4_address]
}
