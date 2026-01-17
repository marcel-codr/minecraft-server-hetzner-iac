# Environment Setup Guide

This guide provides detailed instructions for setting up new environments in the Minecraft Server Hetzner IaC project.

## Overview

Environments in this project represent isolated deployments of Minecraft servers. Each environment:

- Deploys to a separate Hetzner Cloud project
- Has its own Terraform state
- Can have different configurations (edition, server type, etc.)
- Is managed independently

## Prerequisites

Before setting up an environment, ensure you have:

1. **Hetzner Cloud Account**: Access to create projects and servers
2. **GitHub CLI**: Install and authenticate (`gh auth login`)
3. **Repository Access**: Push access to manage secrets
4. **Terraform**: Version 1.5.0 or higher

## Step-by-Step Setup

### 1. Run the Setup Script

Execute the interactive setup script:

```bash
./scripts/setup_env.sh
```

### 2. Follow the Guided Workflow

The script guides you through these steps:

#### STEP 1: Create a Hetzner Cloud Project

The script will display instructions to:

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/projects)
2. Click **+ New Project**
3. Name it something like `minecraft-<env-name>` (e.g., `minecraft-dev`, `minecraft-prod`)
4. Go to the project → **Security** → **API Tokens**
5. Generate a new API token with **Read & Write** permissions
6. Copy the token

Press Enter when ready to continue.

#### Environment Name

- Choose a descriptive name (e.g., `dev`, `staging`, `prod`)
- This becomes the directory name under `terraform/environments/`

#### Server Configurations

The script will interactively ask you to configure each server:

- **Server Name**: Unique identifier (e.g., `java-main`, `bedrock-test`)
- **Edition**: `java` or `bedrock`
- **Docker Image**: Container image (defaults based on edition)
- **Server Type**: Hetzner instance type from the menu
- **Location**: Datacenter location

After configuring each server, you'll be asked if you want to add another server.

Available server types:
| Type | vCPU | RAM | Architecture | Monthly Cost |
|------|------|-----|--------------|-------------|
| **cx23** | 2 | 4 GB | x86 | ~€3.56 |
| **cx33** | 4 | 8 GB | x86 | ~€7.11 |
| **cx43** | 8 | 16 GB | x86 | ~€14.22 |
| **cax11** | 2 | 4 GB | ARM | ~€3.92 |
| **Custom** | - | - | - | - |

Locations:

- **nbg1**: Nuremberg, Germany (default)
- **fsn1**: Falkenstein, Germany
- **hel1**: Helsinki, Finland

#### STEP 2: SSH Keys (Optional)

- Enter the names of SSH keys you've uploaded to your Hetzner project
- These must match the key names in Hetzner Cloud Console → Security → SSH Keys
- Leave empty to skip (you won't be able to SSH into the server)

#### STEP 3: Hetzner Cloud API Token

- Enter the API token you created for this environment's Hetzner project
- This token is specific to the project you created in Step 1
- The token is stored as a GitHub secret for CI/CD

## What Happens During Setup

The setup script performs the following actions:

1. **Guides Project Creation**: Displays instructions for creating a dedicated Hetzner project
2. **Validates Input**: Checks for required fields and valid options
3. **Creates Environment Directory**: `terraform/environments/<env-name>/`
4. **Generates Configuration**: Creates `main.tf` and `backend.tf` from templates
5. **Adds GitHub Secret**: Stores the project token as `HETZNER_TOKEN_<ENV_NAME>`
6. **Initializes Terraform**: Runs `terraform init` in the environment directory

## Post-Setup Steps

### Verify Configuration

Check the generated files:

```bash
cd terraform/environments/<env-name>
cat main.tf
```

### First Deployment

Set the API token and deploy:

```bash
export HCLOUD_TOKEN='<your-project-token>'
terraform plan
terraform apply
```

### Access Your Server

After deployment:

1. Get the server IP: `terraform output ips`
2. Connect to Minecraft using the IP and port:
   - Java Edition: `<ip>:25565`
   - Bedrock Edition: `<ip>:19132` (UDP)

### SSH Access (if configured)

If you added SSH keys:

```bash
ssh root@<server-ip>
```

## Managing Environments

### Update Configuration

Edit `terraform/environments/<env-name>/main.tf` to modify settings, then:

```bash
terraform plan
terraform apply
```

### Destroy Environment

To completely remove the environment:

```bash
terraform destroy
```

### Add More Environments

Run `./scripts/setup_env.sh` again with a different environment name.

## Troubleshooting

### Common Issues

**"gh secret set failed"**

- Ensure GitHub CLI is installed: `brew install gh`
- Authenticate: `gh auth login`
- Check repository access permissions

**"Invalid server type"**

- Use `hcloud server-type list` to see available types
- Valid types include: `cx23`, `cx33`, `cx43`, `cax11`
- Check current pricing at https://www.hetzner.com/cloud

**"Token invalid"**

- Ensure you're using a **project-specific** API token with Read & Write permissions
- Regenerate the token in Hetzner Console if needed
- Update the GitHub secret manually or re-run setup

### Getting Help

- Check Terraform logs for detailed error messages
- Review Hetzner Cloud status page for outages
- Open an issue in the repository for bugs

## Best Practices

- **Start Small**: Use `cx23` for initial testing (~€3.56/month)
- **Monitor Usage**: Check Hetzner Console for resource usage
- **Backup Important Worlds**: Implement regular backups
- **Use Different Projects**: Keep environments isolated in separate Hetzner projects
- **Version Control**: Commit environment configurations
- **Add SSH Keys**: Always configure SSH access for debugging

## Project Isolation

Each environment should have its own dedicated Hetzner project. This ensures:

- **Complete isolation** between environments (dev, staging, prod)
- **Separate billing** per project
- **Independent API tokens** for security
- **Clean resource management**

**Token Security:**

- Use project-specific tokens (not account-level)
- Each token only has access to its own project
- Consider rotating tokens regularly
- Tokens are stored securely as GitHub secrets
