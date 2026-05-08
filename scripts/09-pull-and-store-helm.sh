#!/bin/bash

# Script: 09-pull-and-store-helm.sh
# Description: Pull Helm charts from public repos and store them locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CHARTS_FILE="${ROOT_DIR}/config/charts-to-pull.txt"
HELM_REPOS_DIR="${ROOT_DIR}/helm-repos"

echo "=========================================="
echo "Pull and Store Helm Charts Locally"
echo "=========================================="

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed"
    exit 1
fi

# Function to pull and store chart
pull_and_store_chart() {
    local repo_name=$1
    local chart_name=$2
    local chart_version=$3
    local target_dir=$4
    
    echo ""
    echo "Processing: ${chart_name}"
    echo "  Repository: ${repo_name}"
    echo "  Version: ${chart_version:-latest}"
    echo "  Target: ${target_dir}"
    
    # Add repository if not exists
    if ! helm repo list | grep -q "^${repo_name}"; then
        echo "  Adding repository: ${repo_name}"
        case $repo_name in
            cilium)
                helm repo add cilium https://helm.cilium.io/ || true
                ;;
            metallb)
                helm repo add metallb https://metallb.github.io/metallb || true
                ;;
            prometheus-community)
                helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
                ;;
            grafana)
                helm repo add grafana https://grafana.github.io/helm-charts || true
                ;;
            bitnami)
                helm repo add bitnami https://charts.bitnami.com/bitnami || true
                ;;
            kong)
                helm repo add kong https://charts.konghq.com || true
                ;;
            milvus)
                helm repo add milvus https://milvus-io.github.io/milvus-helm || true
                ;;
            minio)
                helm repo add minio https://charts.min.io || true
                ;;
            *)
                echo "  WARNING: Unknown repository: ${repo_name}"
                return 1
                ;;
        esac
    fi
    
    # Update repositories
    helm repo update "${repo_name}" || true
    
    # Create target directory
    mkdir -p "${target_dir}"
    
    # Pull chart
    echo "  Pulling chart..."
    if [ -n "$chart_version" ] && [ "$chart_version" != "latest" ]; then
        helm pull "${repo_name}/${chart_name}" --version "${chart_version}" --untar --untardir "${target_dir}" || {
            echo "  WARNING: Failed to pull ${chart_name} version ${chart_version}"
            return 1
        }
    else
        helm pull "${repo_name}/${chart_name}" --untar --untardir "${target_dir}" || {
            echo "  WARNING: Failed to pull ${chart_name}"
            return 1
        }
    fi
    
    # Move to final location
    if [ -d "${target_dir}/${chart_name}" ]; then
        mv "${target_dir}/${chart_name}" "${target_dir}/${chart_name}-pulled" || true
        echo "  ✓ Successfully stored: ${target_dir}/${chart_name}"
    fi
}

# Create charts list if it doesn't exist
if [ ! -f "$CHARTS_FILE" ]; then
    echo "Creating default charts list..."
    mkdir -p "$(dirname "$CHARTS_FILE")"
    cat > "$CHARTS_FILE" <<EOF
# Helm charts to pull and store locally
# Format: repo_name chart_name version target_category
# Categories: platform or application

# Platform Components
cilium cilium 1.14.0 platform
metallb metallb 0.14.0 platform
prometheus-community kube-prometheus-stack 55.0.0 platform
grafana grafana 7.3.0 platform
prometheus-community alertmanager 0.1.0 platform
kong kong 2.19.0 platform

# Application Components
bitnami postgresql 15.0.0 application
minio minio 5.0.0 application
milvus milvus 4.0.0 application
bitnami redis 17.0.0 application
EOF
fi

# Process charts
echo ""
echo "Processing charts from: $CHARTS_FILE"
echo ""

success_count=0
fail_count=0

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse line: repo_name chart_name version category
    repo_name=$(echo "$line" | awk '{print $1}')
    chart_name=$(echo "$line" | awk '{print $2}')
    chart_version=$(echo "$line" | awk '{print $3}')
    category=$(echo "$line" | awk '{print $4}')
    
    if [ -z "$repo_name" ] || [ -z "$chart_name" ]; then
        echo "WARNING: Invalid line format: $line"
        continue
    fi
    
    # Default category
    category="${category:-platform}"
    target_dir="${HELM_REPOS_DIR}/${category}/${chart_name}"
    
    if pull_and_store_chart "$repo_name" "$chart_name" "$chart_version" "$target_dir"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
done < "$CHARTS_FILE"

# Update repository indexes
echo ""
echo "Updating repository indexes..."
for category in platform application; do
    if [ -d "${HELM_REPOS_DIR}/${category}" ]; then
        echo "  Updating index for ${category}..."
        helm repo index "${HELM_REPOS_DIR}/${category}" --url "file://${HELM_REPOS_DIR}/${category}" || true
    fi
done

echo ""
echo "=========================================="
echo "Helm Chart Pull and Store Complete"
echo "=========================================="
echo "Success: $success_count"
echo "Failed: $fail_count"
echo ""
echo "Charts stored in: ${HELM_REPOS_DIR}/"
