locals {
  # Create a map of server configs for easier lookup
  server_configs = { for server in var.servers : server.name => server }

  # Check if we have any Java or Bedrock servers
  has_java    = length([for s in var.servers : s if s.edition == "java"]) > 0
  has_bedrock = length([for s in var.servers : s if s.edition == "bedrock"]) > 0
}

# Firewall for Minecraft servers
resource "hcloud_firewall" "minecraft" {
  name = "${var.name_prefix}-minecraft-fw"

  # SSH access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Java Edition (TCP 25565)
  dynamic "rule" {
    for_each = local.has_java ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "25565"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }

  # Bedrock Edition (UDP 19132)
  dynamic "rule" {
    for_each = local.has_bedrock ? [1] : []
    content {
      direction  = "in"
      protocol   = "udp"
      port       = "19132"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "hcloud_server" "minecraft_servers" {
  for_each = local.server_configs

  name         = "${var.name_prefix}-${each.value.name}"
  server_type  = each.value.server_type
  image        = "ubuntu-22.04"
  location     = each.value.location
  user_data    = each.value.edition == "java" ? module.minecraft_java[each.key].cloud_init : module.minecraft_bedrock[each.key].cloud_init
  ssh_keys     = var.ssh_keys
  firewall_ids = [hcloud_firewall.minecraft.id]
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
