# Minecraft Server Hetzner IaC

Infrastructure as Code (IaC) project for automated setup, deployment, and maintenance of Minecraft servers on Hetzner Cloud. Supports both Java and Bedrock editions, with isolated environments for different projects.

## Features

- **Dynamic Server Deployment**: Define multiple Minecraft servers per environment with different configurations
- **Multi-Edition Support**: Java and Bedrock editions with custom Docker images
- **Flexible Scaling**: Mix server types and locations within the same environment
- **Environment Isolation**: Each environment deploys to a separate Hetzner project
- **Custom Domains**: Optional DNS configuration via Hetzner DNS
- **Firewall Protection**: Automatic firewall rules for Minecraft ports only
- **Auto-Updates**: Daily cron job to pull latest Docker images
- **GitHub Setup Workflow**: Create and deploy environments from GitHub
- **CI/CD Integration**: GitHub Actions for automatic deployments on code changes
- **Docker-Based**: Uses official Minecraft Docker images from itzg

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) (v1.5.0+)
- [GitHub CLI](https://cli.github.com/) (for automated secret management)
- Hetzner Cloud account with API access
- Bash shell (for setup scripts)

## Quick Start

1. **Clone the repository**:

   ```bash
   git clone https://github.com/marcel-codr/minecraft-server-hetzner-iac.git
   cd minecraft-server-hetzner-iac
   ```

2. **Create a new environment**:

   ```bash
   ./scripts/setup_env.sh
   ```

   Follow the prompts to configure your environment (edition, server type, etc.).

   📖 **Detailed Setup Guide**: See [docs/environment-setup.md](docs/environment-setup.md) for comprehensive instructions.

3. **Deploy the server**:
   ```bash
   cd terraform/environments/<your-env>
   terraform plan
   terraform apply
   ```

Your Minecraft server will be running on a Hetzner VPS with the specified configuration.

## Detailed Usage

### Setting Up Environments

Environments represent separate deployments (e.g., dev, staging, prod) and are isolated in different Hetzner projects.

Run `./scripts/setup_env.sh` or the **GitHub Setup Environment** workflow and follow the guided workflow:

1. **Create a Hetzner Project** (manually in Hetzner Console)
2. **Configure servers** interactively (edition, docker image, server type, location)
3. **Add SSH keys** (optional, for server access)
4. **Enter the project-specific API token**

📖 **Complete Guide**: [Environment Setup Documentation](docs/environment-setup.md)

The script will:

- Guide you through creating a dedicated Hetzner project
- Create the environment directory
- Generate Terraform configuration
- Add the API token as a GitHub secret for CI/CD
- Initialize Terraform

### Managing Deployments

For each environment:

```bash
cd terraform/environments/<env-name>

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy environment
terraform destroy
```

### Server Configuration

Servers are deployed with:

- Ubuntu 22.04
- Docker installed via cloud-init
- Minecraft server running in a container
- Port 25565 (Java) or 19132/UDP (Bedrock) exposed

Customize by editing `terraform/environments/<env>/main.tf` or the module templates.

### Adding SSH Access

To enable SSH access to servers:

1. Add SSH keys to your Hetzner project
2. Specify key names when creating the environment
3. SSH to the server: `ssh root@<server-ip>`

## Architecture

```
terraform/
├── modules/
│   ├── minecraft-java/     # Java edition server module
│   └── minecraft-bedrock/  # Bedrock edition server module
├── platforms/
│   └── hetzner/            # Hetzner-specific platform with dynamic server support
├── environments/           # Environment-specific deployments
│   └── <env-name>/
│       ├── main.tf         # Defines servers list with configurations
│       └── backend.tf
└── templates/              # Configuration templates

docs/                       # Detailed documentation
└── environment-setup.md   # Comprehensive environment setup guide
```

- **Modules**: Reusable components for server setup (Java/Bedrock)
- **Platforms**: Cloud-provider specific implementations with dynamic server iteration
- **Environments**: Isolated deployments defining multiple servers with custom configs

## CI/CD

The repository includes a GitHub Actions workflow (`deployment.yml`) that:

- Triggers on changes to `terraform/` directory
- Deploys to all configured environments
- Uses per-environment API tokens from repository secrets

### Setting Up CI

1. Ensure GitHub CLI is authenticated: `gh auth login`
2. Create environments with `./scripts/setup_env.sh` (adds secrets automatically)
3. Push changes to trigger deployments

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test locally:
   - Create a test environment
   - Run `terraform plan` and `terraform apply`
5. Commit your changes: `git commit -m "Add your feature"`
6. Push to your fork: `git push origin feature/your-feature`
7. Create a Pull Request

### Guidelines

- Follow Terraform best practices
- Update documentation for any new features
- Test changes in a non-production environment first
- Use descriptive commit messages

### Reporting Issues

- Use GitHub Issues for bugs and feature requests
- Provide detailed steps to reproduce
- Include Terraform version and error messages

### Code Style

- Use consistent Terraform formatting: `terraform fmt`
- Follow the existing module structure
- Add comments for complex logic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or support:

- Check the [GitHub Issues](https://github.com/marcel-codr/minecraft-server-hetzner-iac/issues)
- Review the Terraform documentation
- Consult Hetzner Cloud documentation
