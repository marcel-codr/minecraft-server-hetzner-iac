# GitHub Workflows

This document describes the GitHub Actions workflows used for CI/CD in this project.

## Setup Environment Workflow

**File:** `.github/workflows/setup-environment.yml`

### Overview

Create and deploy a new Minecraft server environment directly from GitHub without using the command line.

### Trigger

Manual dispatch only - triggered from the GitHub Actions tab with input parameters.

### Inputs

| Input              | Required | Default   | Description                                 |
| ------------------ | -------- | --------- | ------------------------------------------- |
| `environment_name` | Yes      | -         | Environment name (e.g., dev, staging, prod) |
| `server_name`      | Yes      | minecraft | Server name identifier                      |
| `edition`          | Yes      | java      | Minecraft edition (java/bedrock)            |
| `server_type`      | Yes      | cx23      | Hetzner server type                         |
| `location`         | Yes      | nbg1      | Hetzner datacenter                          |
| `domain`           | No       | -         | Domain subdomain (e.g., "mc")               |
| `dns_zone`         | No       | -         | DNS zone (e.g., example.com)                |
| `ssh_keys`         | No       | -         | SSH key names (comma-separated)             |
| `hetzner_token`    | Yes      | -         | Hetzner Cloud API token                     |

### How to Use

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Setup Environment** workflow
4. Click **Run workflow**
5. Fill in the required inputs:
   - Environment name
   - Server configuration
   - Hetzner API token (from your Hetzner project)
6. Click **Run workflow**

### What It Does

1. Creates the environment directory
2. Generates `main.tf` and `backend.tf`
3. Initializes Terraform
4. Stores the Hetzner token as a GitHub secret
5. Commits the environment files
6. Deploys the server
7. Outputs the server IP in the workflow summary

### Prerequisites

Before running this workflow:

1. Create a Hetzner Cloud project
2. Generate an API token for that project
3. (Optional) Add SSH keys to the project
4. (Optional) Create a DNS zone in Hetzner DNS

---

## Deployment Workflow

**File:** `.github/workflows/deployment.yml`

### Overview

The deployment workflow automatically deploys Minecraft servers to Hetzner Cloud when changes are pushed to the `terraform/` directory.

### Triggers

The workflow runs on:

1. **Push to `terraform/**`\*\*: Any changes to Terraform files trigger a deployment
2. **Manual dispatch**: Can be triggered manually from the GitHub Actions tab

```yaml
on:
  push:
    paths:
      - "terraform/**"
  workflow_dispatch: {}
```

### How It Works

1. **Checkout**: Clones the repository
2. **Setup Terraform**: Installs Terraform v1.5.0
3. **Find Environments**: Discovers all environments in `terraform/environments/`
4. **Deploy**: For each environment:
   - Looks for a secret named `HETZNER_TOKEN_<ENV_NAME>` (uppercase)
   - Skips if no secret is found
   - Runs `terraform init` and `terraform apply -auto-approve`

### Required Secrets

For each environment, you need a corresponding GitHub secret:

| Environment | Secret Name             |
| ----------- | ----------------------- |
| `dev`       | `HETZNER_TOKEN_DEV`     |
| `staging`   | `HETZNER_TOKEN_STAGING` |
| `prod`      | `HETZNER_TOKEN_PROD`    |
| `<name>`    | `HETZNER_TOKEN_<NAME>`  |

The setup script (`./scripts/setup_env.sh`) automatically creates these secrets when you create a new environment.

### Manual Secret Setup

If you need to add secrets manually:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `HETZNER_TOKEN_<ENV_NAME>` (e.g., `HETZNER_TOKEN_PROD`)
5. Value: Your Hetzner Cloud API token for that environment's project

Or use the GitHub CLI:

```bash
echo "your-token" | gh secret set HETZNER_TOKEN_PROD
```

### Workflow Behavior

- **Auto-approve**: The workflow uses `-auto-approve` flag, meaning changes are applied without manual confirmation
- **Skip missing secrets**: Environments without a corresponding secret are skipped (not failed)
- **Sequential deployment**: Environments are deployed one at a time

### Example Run

```
Deploying to dev
Initializing Terraform...
Applying changes...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Deploying to prod
Initializing Terraform...
Applying changes...
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

## Manual Trigger

To manually trigger the deployment:

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Deployment** workflow
4. Click **Run workflow**
5. Select the branch and click **Run workflow**

## Troubleshooting

### "No HETZNER*TOKEN*<ENV> secret found"

The workflow couldn't find a secret for that environment. Either:

- The secret wasn't created during setup
- The secret name doesn't match (check uppercase)

**Fix:** Add the secret manually or re-run the setup script.

### "Error: Missing Hetzner Cloud API token"

The secret exists but is empty or invalid.

**Fix:** Update the secret with a valid Hetzner Cloud API token.

### Terraform State Conflicts

If multiple workflow runs happen simultaneously, you may get state lock errors.

**Fix:** Wait for the current run to complete, or use remote state backend (e.g., Terraform Cloud).

## Security Considerations

- **Secrets are encrypted**: GitHub encrypts all secrets at rest
- **Secrets are masked**: Secret values are masked in logs
- **Project isolation**: Each environment uses a separate Hetzner project with its own token
- **Minimal permissions**: Use project-specific tokens, not account-level tokens

## Extending the Workflow

### Add Terraform Plan Step

To add a plan step before apply:

```yaml
- name: Plan environments
  run: |
    for env in $(echo ${{ steps.find-envs.outputs.environments }} | jq -r '.[]'); do
      export HCLOUD_TOKEN=${{ secrets[format('HETZNER_TOKEN_{0}', env | upper)] }}
      terraform -chdir=terraform/environments/$env plan -out=tfplan
    done
```

### Add Notifications

To add Slack notifications:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {"text": "Deployment completed for ${{ github.repository }}"}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Add Environment Protection

For production environments, consider adding:

- Required reviewers
- Wait timers
- Branch restrictions

Configure these in **Settings** → **Environments** on GitHub.
