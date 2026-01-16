#!/usr/bin/env bash
# Interactive setup script to create a new Terraform environment
set -euo pipefail

TEMPLATE_DIR="terraform/templates"
ENVIRONMENTS_DIR="terraform/environments"

echo "Minecraft Server Terraform Environment Setup"
echo "=============================================="

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
  echo "  1) cx11 (1 vCPU, 2GB RAM)"
  echo "  2) cpx11 (2 vCPU, 2GB RAM)"
  echo "  3) cx21 (2 vCPU, 4GB RAM)"
  echo "  4) cpx21 (3 vCPU, 4GB RAM)"
  echo "  5) Custom"
  read -p "  Choose server type [1]: " SERVER_CHOICE
  SERVER_CHOICE=${SERVER_CHOICE:-1}
  case $SERVER_CHOICE in
    1) SERVER_TYPE="cx11" ;;
    2) SERVER_TYPE="cpx11" ;;
    3) SERVER_TYPE="cx21" ;;
    4) SERVER_TYPE="cpx21" ;;
    5) read -p "  Enter custom server type: " SERVER_TYPE ;;
    *) echo "Invalid choice, using cx11"; SERVER_TYPE="cx11" ;;
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
  if [ $i -gt 1 ]; then
    read -p "Do you want to add another server? (y/N): " ADD_ANOTHER
    if [[ ! "$ADD_ANOTHER" =~ ^[Yy]$ ]]; then
      break
    fi
    SERVERS_CONFIG="${SERVERS_CONFIG},
"
  fi

  i=$((i + 1))
done
SERVERS_CONFIG="${SERVERS_CONFIG}
]"

# Ask for SSH keys (optional)
read -p "Enter SSH key names (comma-separated, optional): " SSH_KEYS_INPUT
SSH_KEYS="[]"
if [ -n "$SSH_KEYS_INPUT" ]; then
  # Format as list
  SSH_KEYS=$(echo "$SSH_KEYS_INPUT" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
fi

# Ask for Hetzner token (project-specific)
read -p "Enter Hetzner Cloud API token for this environment/project: " HCLOUD_TOKEN
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "Hetzner token cannot be empty."
  exit 1
fi

# Ask for project creation details (always required)
read -p "Enter project name: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-"$ENV_NAME-minecraft"}
read -p "Enter account-level API token (for project creation): " ACCOUNT_TOKEN
if [ -z "$ACCOUNT_TOKEN" ]; then
  echo "Account token required for project creation."
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

# Export for terraform init
export HETZNER_TOKEN="$HCLOUD_TOKEN"

# Create environment directory
mkdir -p "$ENV_DIR"

# Copy and fill templates
cp "$TEMPLATE_DIR/backend.tf.template" "$ENV_DIR/backend.tf"

# Fill main.tf template
MAIN_TEMPLATE=$(cat "$TEMPLATE_DIR/main.tf.template")
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{ENV_NAME\}\}/$ENV_NAME}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{ACCOUNT_TOKEN\}\}/$ACCOUNT_TOKEN}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{SERVERS_CONFIG\}\}/$SERVERS_CONFIG}
MAIN_TEMPLATE=${MAIN_TEMPLATE//\{\{SSH_KEYS\}\}/$SSH_KEYS}

echo "$MAIN_TEMPLATE" > "$ENV_DIR/main.tf"

echo "Environment '$ENV_NAME' created at $ENV_DIR"
echo "Initializing Terraform..."
terraform -chdir="$ENV_DIR" init
echo "Done. You can now run: terraform -chdir=$ENV_DIR plan"
