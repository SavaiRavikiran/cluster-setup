#!/bin/bash

# Interactive Deployment Helper
# Makes it easy for developers to deploy/update components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo "=========================================="
echo "  Nova Cluster - Interactive Deployment"
echo "=========================================="
echo ""

# Select environment
echo "Select Environment:"
echo "1) Development (dev)"
echo "2) Staging"
echo "3) Production (prod)"
read -p "Enter choice [1-3]: " env_choice

case $env_choice in
    1) ENV="dev" ;;
    2) ENV="staging" ;;
    3) ENV="prod" ;;
    *) ENV="dev" ;;
esac

echo ""
echo "Selected: $ENV"
echo ""

# Select component category
echo "Select Component Category:"
echo "1) Platform Components"
echo "2) Application Components"
echo "3) All Components"
read -p "Enter choice [1-3]: " cat_choice

case $cat_choice in
    1) CATEGORY="platform" ;;
    2) CATEGORY="application" ;;
    3) CATEGORY="all" ;;
    *) CATEGORY="platform" ;;
esac

# Get components list
if [ "$CATEGORY" = "platform" ]; then
    COMPONENTS=("cilium" "metallb" "metrics-server" "nfs-provisioner" "kong" "gitlab" "gitlab-runner" "prometheus" "grafana" "alertmanager" "wiz")
elif [ "$CATEGORY" = "application" ]; then
    COMPONENTS=("postgresql" "minio" "milvus" "novaridium-app" "flyte" "ollama" "openfga" "langfuse" "neo4j" "redis" "prefect")
else
    COMPONENTS=("cilium" "metallb" "postgresql" "minio" "novaridium-app")
fi

# Show components
echo ""
echo "Available Components:"
for i in "${!COMPONENTS[@]}"; do
    echo "$((i+1))) ${COMPONENTS[$i]}"
done
echo "$((${#COMPONENTS[@]}+1))) All listed components"
echo "$((${#COMPONENTS[@]}+2))) Custom component name"

read -p "Enter choice: " comp_choice

# Get component name
if [ "$comp_choice" -eq $((${#COMPONENTS[@]}+1)) ]; then
    # Deploy all
    echo ""
    echo "Deploying all components to $ENV..."
    for comp in "${COMPONENTS[@]}"; do
        echo ""
        echo "Deploying $comp..."
        "$ROOT_DIR/cli/nova" deploy "$comp" "$ENV" || echo "Failed to deploy $comp"
    done
elif [ "$comp_choice" -eq $((${#COMPONENTS[@]}+2)) ]; then
    read -p "Enter component name: " COMPONENT
    "$ROOT_DIR/cli/nova" deploy "$COMPONENT" "$ENV"
else
    COMPONENT="${COMPONENTS[$((comp_choice-1))]}"
    echo ""
    echo "Deploying $COMPONENT to $ENV..."
    "$ROOT_DIR/cli/nova" deploy "$COMPONENT" "$ENV"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
