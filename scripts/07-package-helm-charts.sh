#!/bin/bash

# Script: 07-package-helm-charts.sh
# Description: Package and index local Helm charts for use in CI/CD

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HELM_CHARTS_DIR="${ROOT_DIR}/helm-charts"

echo "=========================================="
echo "Packaging Local Helm Charts"
echo "=========================================="

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed. Please install Helm 3.x"
    exit 1
fi

# Create charts directory structure
mkdir -p "${HELM_CHARTS_DIR}"/{cluster,monitoring,novaridium}

# Function to package a chart if Chart.yaml exists
package_chart() {
    local chart_dir=$1
    local chart_name=$(basename "$chart_dir")
    
    if [ -f "${chart_dir}/Chart.yaml" ]; then
        echo "Packaging ${chart_name}..."
        helm package "${chart_dir}" -d "${HELM_CHARTS_DIR}" || echo "Warning: Failed to package ${chart_name}"
    else
        echo "Skipping ${chart_name} (no Chart.yaml found)"
    fi
}

# Package cluster charts
echo ""
echo "Packaging cluster charts..."
for chart_dir in "${ROOT_DIR}"/cluster/*; do
    if [ -d "$chart_dir" ]; then
        package_chart "$chart_dir"
    fi
done

# Package monitoring charts
echo ""
echo "Packaging monitoring charts..."
for chart_dir in "${ROOT_DIR}"/monitoring/*; do
    if [ -d "$chart_dir" ]; then
        package_chart "$chart_dir"
    fi
done

# Package novaridium charts
echo ""
echo "Packaging novaridium charts..."
for chart_dir in "${ROOT_DIR}"/novaridium/*; do
    if [ -d "$chart_dir" ]; then
        package_chart "$chart_dir"
    fi
done

# Create or update index
echo ""
echo "Creating Helm repository index..."
helm repo index "${HELM_CHARTS_DIR}" --url "file://${HELM_CHARTS_DIR}" || {
    echo "Warning: Failed to create index. This is OK if no charts were packaged."
}

echo ""
echo "=========================================="
echo "Helm Charts Packaging Complete"
echo "=========================================="
echo ""
echo "Charts are available in: ${HELM_CHARTS_DIR}"
echo ""
echo "To use locally:"
echo "  helm repo add local-charts file://${HELM_CHARTS_DIR}"
echo "  helm repo update"
echo ""
