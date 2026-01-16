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

1. **Hetzner Cloud Account**: With permission to create projects
2. **Account-Level API Token**: Generate a token with project creation permissions
3. **GitHub CLI**: Install and authenticate (`gh auth login`)
4. **Repository Access**: Push access to manage secrets

## Step-by-Step Setup

### 1. Prepare Account-Level API Token

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Go to **Security** → **API Tokens**
3. Create a new token with **account-level permissions** (can create projects)
4. **Copy the token immediately** - it won't be shown again

This token will be used to create the project automatically.

### 2. Run the Setup Script

Execute the interactive setup script:

```bash
./scripts/setup_env.sh
```

### 3. Configure Environment Details

The script will prompt for the following information:

#### Environment Name
- Choose a descriptive name (e.g., `dev`, `staging`, `prod`)
- This becomes the directory name under `terraform/environments/`
- Example: `dev`

#### Server Configurations
The script will interactively ask you to configure each server one by one:

For each server, provide:

- **Server Name**: Unique identifier (e.g., `java-main`, `bedrock-test`)
- **Edition**: `java` or `bedrock`
- **Docker Image**: Container image (defaults based on edition)
- **Server Type**: Hetzner instance type from the menu
- **Location**: Datacenter location

After configuring each server, you'll be asked if you want to add another server. Answer `y` to add more servers or `n` to finish.

Available server types:
1. **cx11** (1 vCPU, 2GB RAM) - Basic
2. **cpx11** (2 vCPU, 2GB RAM) - Balanced
3. **cx21** (2 vCPU, 4GB RAM) - Standard
4. **cpx21** (3 vCPU, 4GB RAM) - Performance
5. **Custom**: Enter any Hetzner server type

Locations:
- **nbg1**: Nuremberg, Germany
- **fsn1**: Falkenstein, Germany
- **hel1**: Helsinki, Finland

#### Project Name
- Name for the new Hetzner project that will be created
- Example: "Minecraft Dev Server", "Production Minecraft"
- Default: `<environment-name>-minecraft`

#### Account-Level API Token
- The account-level token you created earlier
- Must have permissions to create projects
- This token is stored as a GitHub secret for CI/CD

## What Happens During Setup

The setup script performs the following actions:

1. **Validates Input**: Checks for required fields and valid options
2. **Creates Environment Directory**: `terraform/environments/<env-name>/`
3. **Generates Configuration**: Creates `main.tf` and `backend.tf` from templates
4. **Adds GitHub Secret**: Stores the account token as `HETZNER_TOKEN_<ENV_NAME>`
5. **Initializes Terraform**: Runs `terraform init` in the environment directory

## Post-Setup Steps

### Verify Configuration

Check the generated files:

```bash
cd terraform/environments/<env-name>
cat main.tf
```

### First Deployment

Deploy the server:

```bash
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
- Verify the server type exists in Hetzner
- Check current pricing at https://www.hetzner.com/cloud

**"Token invalid"**
- Ensure you're using an **account-level** API token with project creation permissions
- Regenerate the token in Hetzner Console if needed
- Update the GitHub secret manually or re-run setup

### Getting Help

- Check Terraform logs for detailed error messages
- Review Hetzner Cloud status page for outages
- Open an issue in the repository for bugs

## Best Practices

- **Start Small**: Use cx11 for initial testing
- **Monitor Usage**: Check Hetzner Console for resource usage
- **Backup Important Worlds**: Implement regular backups
- **Use Different Projects**: Keep environments isolated
- **Version Control**: Commit environment configurations

## Project Creation Details

The setup automatically creates a new Hetzner project for each environment using the account-level API token. This ensures complete isolation between environments.

**What gets created:**
- New Hetzner project with the specified name
- Server deployed in the new project
- All resources are scoped to the project

**Token Security:**
- Account-level tokens have broad permissions - use carefully
- Consider rotating tokens regularly
- The token is stored securely as a GitHub secret