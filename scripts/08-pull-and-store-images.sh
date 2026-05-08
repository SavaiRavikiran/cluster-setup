#!/bin/bash

# Script: 08-pull-and-store-images.sh
# Description: Pull public images and store them in GitLab container registry

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGES_FILE="${ROOT_DIR}/config/images-to-pull.txt"
REGISTRY="${CI_REGISTRY:-registry.gitlab.com}"
REGISTRY_PATH="${CI_REGISTRY_IMAGE:-${CI_PROJECT_PATH}}/images"

echo "=========================================="
echo "Pull and Store Images in GitLab Registry"
echo "=========================================="

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Login to GitLab registry
if [ -z "$CI_REGISTRY_USER" ] || [ -z "$CI_REGISTRY_PASSWORD" ]; then
    echo "ERROR: CI_REGISTRY_USER and CI_REGISTRY_PASSWORD must be set"
    exit 1
fi

echo "Logging in to GitLab registry..."
echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$REGISTRY"

# Function to pull and push image
pull_and_store() {
    local source_image=$1
    local target_image=$2
    
    echo ""
    echo "Processing: ${source_image}"
    echo "  Source: ${source_image}"
    echo "  Target: ${target_image}"
    
    # Pull image
    echo "  Pulling image..."
    docker pull "${source_image}" || {
        echo "  WARNING: Failed to pull ${source_image}"
        return 1
    }
    
    # Tag image
    echo "  Tagging image..."
    docker tag "${source_image}" "${target_image}" || {
        echo "  ERROR: Failed to tag image"
        return 1
    }
    
    # Push image
    echo "  Pushing to registry..."
    docker push "${target_image}" || {
        echo "  ERROR: Failed to push image"
        return 1
    }
    
    echo "  ✓ Successfully stored: ${target_image}"
}

# Create images list if it doesn't exist
if [ ! -f "$IMAGES_FILE" ]; then
    echo "Creating default images list..."
    mkdir -p "$(dirname "$IMAGES_FILE")"
    cat > "$IMAGES_FILE" <<EOF
# Images to pull and store in GitLab registry
# Format: source_image:tag target_image:tag

# Platform Components
cilium/cilium:latest ${REGISTRY}/${REGISTRY_PATH}/cilium:latest
metallb/speaker:v0.14.0 ${REGISTRY}/${REGISTRY_PATH}/metallb-speaker:v0.14.0
metallb/controller:v0.14.0 ${REGISTRY}/${REGISTRY_PATH}/metallb-controller:v0.14.0
registry.k8s.io/metrics-server/metrics-server:v0.6.3 ${REGISTRY}/${REGISTRY_PATH}/metrics-server:v0.6.3
kong/kong:latest ${REGISTRY}/${REGISTRY_PATH}/kong:latest
gitlab/gitlab-ce:latest ${REGISTRY}/${REGISTRY_PATH}/gitlab-ce:latest
gitlab/gitlab-runner:latest ${REGISTRY}/${REGISTRY_PATH}/gitlab-runner:latest
prom/prometheus:latest ${REGISTRY}/${REGISTRY_PATH}/prometheus:latest
grafana/grafana:latest ${REGISTRY}/${REGISTRY_PATH}/grafana:latest
prom/alertmanager:latest ${REGISTRY}/${REGISTRY_PATH}/alertmanager:latest

# Application Components
postgres:15 ${REGISTRY}/${REGISTRY_PATH}/postgres:15
minio/minio:latest ${REGISTRY}/${REGISTRY_PATH}/minio:latest
milvusdb/milvus:latest ${REGISTRY}/${REGISTRY_PATH}/milvus:latest
ollama/ollama:latest ${REGISTRY}/${REGISTRY_PATH}/ollama:latest
redis:7 ${REGISTRY}/${REGISTRY_PATH}/redis:7
neo4j:latest ${REGISTRY}/${REGISTRY_PATH}/neo4j:latest
prefecthq/prefect:latest ${REGISTRY}/${REGISTRY_PATH}/prefect:latest
EOF
fi

# Process images
echo ""
echo "Processing images from: $IMAGES_FILE"
echo ""

success_count=0
fail_count=0

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse line: source_image target_image
    source_image=$(echo "$line" | awk '{print $1}')
    target_image=$(echo "$line" | awk '{print $2}')
    
    if [ -z "$source_image" ] || [ -z "$target_image" ]; then
        echo "WARNING: Invalid line format: $line"
        continue
    fi
    
    if pull_and_store "$source_image" "$target_image"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
done < "$IMAGES_FILE"

echo ""
echo "=========================================="
echo "Image Pull and Store Complete"
echo "=========================================="
echo "Success: $success_count"
echo "Failed: $fail_count"
echo ""
echo "Images stored in: ${REGISTRY}/${REGISTRY_PATH}/"
