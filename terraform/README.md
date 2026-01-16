Short Terraform layout (scaffold)

- `modules/minecraft-java`: generates cloud-init payloads for Java Edition Minecraft servers.
- `modules/minecraft-bedrock`: generates cloud-init payloads for Bedrock Edition Minecraft servers.
- `platforms/hetzner`: Hetzner-specific composition that creates VMs with `hcloud_server` and uses the cloud-init payloads.
- `environments/*`: environment-specific stacks (e.g. `dev`) — run `terraform init/plan/apply` here.

Quick usage:

1. `export HETZNER_TOKEN=...`
2. `./scripts/setup_env.sh`
3. `terraform -chdir=terraform/environments/dev plan`
