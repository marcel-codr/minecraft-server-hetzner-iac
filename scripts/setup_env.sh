#!/usr/bin/env bash
# Interactive setup script to create a new Terraform environment
set -euo pipefail

TEMPLATE_DIR="terraform/templates"
ENVIRONMENTS_DIR="terraform/environments"

echo "Minecraft Server Terraform Environment Setup"
echo "=============================================="
echo ""

# Step 1: Guide user to create a Hetzner project
echo "STEP 1: Create a Hetzner Cloud Project"
echo "---------------------------------------"
echo "Each environment should have its own Hetzner Cloud project for isolation."
echo ""
echo "Please create a new project in Hetzner Cloud Console:"
echo "  1. Go to https://console.hetzner.cloud/projects"
echo "  2. Click '+ New Project'"
echo "  3. Name it something like 'minecraft-<env-name>' (e.g., minecraft-dev, minecraft-prod)"
echo "  4. After creation, go to the project -> Security -> API Tokens"
echo "  5. Generate a new API token with Read & Write permissions"
echo "  6. Copy the token (you'll need it in a moment)"
echo ""
read -p "Press Enter when you have created the project and copied the API token..."
echo ""

# Ask for environment name
read -p "Enter environment name (e.g., dev, staging, prod): " ENV_NAME
if [ -z "$ENV_NAME" ]; then
  echo "Environment name cannot be empty."
  exit 1
fi

ENV_DIR="$ENVIRONMENTS_DIR/$ENV_NAME"
if [ -d "$ENV_DIR" ]; then
  echo "Environment '$ENV_NAME' already exists at $ENV_DIR"
  read -p "Do you want to overwrite it? (y/N): " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
  fi
  rm -rf "$ENV_DIR"
fi

# Collect server configurations
SERVERS_CONFIG="[
"
i=1
while true; do
  echo "Configuring server $i:"

  # Server name
  read -p "  Server name: " SERVER_NAME
  if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="server$i"
  fi

  # Edition
  read -p "  Edition (java/bedrock) [java]: " SERVER_EDITION
  SERVER_EDITION=${SERVER_EDITION:-java}
  if [[ "$SERVER_EDITION" != "java" && "$SERVER_EDITION" != "bedrock" ]]; then
    echo "Invalid edition. Must be 'java' or 'bedrock'."
    exit 1
  fi

  # Docker image
  if [ "$SERVER_EDITION" = "java" ]; then
    DEFAULT_IMAGE="itzg/minecraft-server:latest"
  else
    DEFAULT_IMAGE="itzg/minecraft-bedrock-server:latest"
  fi
  read -p "  Docker image [$DEFAULT_IMAGE]: " SERVER_IMAGE
  SERVER_IMAGE=${SERVER_IMAGE:-$DEFAULT_IMAGE}

  # Server type
  echo "  Available server types:"
  echo "  1) cx23 (2 vCPU, 4GB RAM, x86)"
  echo "  2) cx33 (4 vCPU, 8GB RAM, x86)"
  echo "  3) cx43 (8 vCPU, 16GB RAM, x86)"
  echo "  4) cax11 (2 vCPU, 4GB RAM, ARM)"
  echo "  5) Custom"
  read -p "  Choose server type [1]: " SERVER_CHOICE
  SERVER_CHOICE=${SERVER_CHOICE:-1}
  case $SERVER_CHOICE in
    1) SERVER_TYPE="cx23" ;;
    2) SERVER_TYPE="cx33" ;;
    3) SERVER_TYPE="cx43" ;;
    4) SERVER_TYPE="cax11" ;;
    5) read -p "  Enter custom server type: " SERVER_TYPE ;;
    *) echo "Invalid choice, using cx23"; SERVER_TYPE="cx23" ;;
  esac

  # Location
  read -p "  Location (nbg1/fsn1/hel1) [nbg1]: " SERVER_LOCATION
  SERVER_LOCATION=${SERVER_LOCATION:-nbg1}

  # Add to config
  SERVERS_CONFIG="${SERVERS_CONFIG}  {
    name         = \"$SERVER_NAME\"
    edition      = \"$SERVER_EDITION\"
    docker_image = \"$SERVER_IMAGE\"
    server_type  = \"$SERVER_TYPE\"
    location     = \"$SERVER_LOCATION\"
  }"

  # Ask if user wants to add another server
  read -p "Do you want to add another server? (y/N): " ADD_ANOTHER
  if [[ ! "$ADD_ANOTHER" =~ ^[Yy]$ ]]; then
    break
  fi
  SERVERS_CONFIG="${SERVERS_CONFIG},
"

  i=$((i + 1))
done
SERVERS_CONFIG="${SERVERS_CONFIG}
]"

# Ask for SSH keys (optional)
echo ""
echo "STEP 2: SSH Keys (Optional)"
echo "----------------------------"
echo "Enter the names of SSH keys you've uploaded to your Hetzner project."
echo "These must match the key names in Hetzner Cloud Console -> Security -> SSH Keys."
echo "Leave empty to skip (you won't be able to SSH into the server)."
echo ""
read -p "SSH key names (comma-separated, optional): " SSH_KEYS_INPUT
SSH_KEYS="[]"
if [ -n "$SSH_KEYS_INPUT" ]; then
  # Format as list
  SSH_KEYS=$(echo "$SSH_KEYS_INPUT" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
fi

# Ask for Hetzner token (project-specific)
echo ""
echo "STEP 3: Hetzner Cloud API Token"
echo "--------------------------------"
echo "Enter the API token you created for this environment's Hetzner project."
echo "This token should be specific to the project you created in Step 1."
echo ""
read -p "Hetzner Cloud API token: " HCLOUD_TOKEN
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "Hetzner token cannot be empty."
  exit 1
fi

# Add token to GitHub repo secrets
SECRET_NAME="HETZNER_TOKEN_$(echo $ENV_NAME | tr '[:lower:]' '[:upper:]')"
echo "Adding secret $SECRET_NAME to GitHub repo..."
if command -v gh &> /dev/null; then
  echo "$HCLOUD_TOKEN" | gh secret set "$SECRET_NAME" --body -
  if [ $? -eq 0 ]; then
    echo "Secret added successfully."
  else
    echo "Failed to add secret. Make sure you are authenticated with 'gh auth login' and have push access to the repo."
  fi
else
  echo "GitHub CLI (gh) not found. Please install it and run 'gh auth login', then manually add the secret $SECRET_NAME with value: $HCLOUD_TOKEN"
fi

# Export for terraform init (provider reads HCLOUD_TOKEN env var)
export HCLOUD_TOKEN="$HCLOUD_TOKEN"

# Create environment directory
mkdir -p "$ENV_DIR"

# Copy and fill templates
cp "$TEMPLATE_DIR/backend.tf.template" "$ENV_DIR/backend.tf"

# Fill main.tf template
MAIN_TEMPLATE=$(cat "$TEMPLATE_DIR/main.tf.template")
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{ENV_NAME\}\}/$ENV_NAME}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{SERVERS_CONFIG\}\}/$SERVERS_CONFIG}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{SSH_KEYS\}\}/$SSH_KEYS}

echo "$MAIN_TEMPLATE" > "$ENV_DIR/main.tf"

echo ""
echo "Environment '$ENV_NAME' created at $ENV_DIR"
echo ""
echo "Initializing Terraform..."
terraform -chdir="$ENV_DIR" init

echo ""
echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo ""
echo "Your environment is ready. To deploy:"
echo ""
echo "  1. Set the API token:"
echo "     export HCLOUD_TOKEN='<your-token>'"
echo ""
echo "  2. Review the plan:"
echo "     terraform -chdir=$ENV_DIR plan"
echo ""
echo "  3. Deploy:"
echo "     terraform -chdir=$ENV_DIR apply"
echo ""
echo "  4. To destroy later:"
echo "     terraform -chdir=$ENV_DIR destroy"
echo ""
