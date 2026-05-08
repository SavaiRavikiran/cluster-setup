#!/bin/bash

# Script: 11-cleanup.sh
# Description: Cleanup activities for old images, charts, and resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Cleanup Activities"
echo "=========================================="

# Configuration
KEEP_IMAGES=${KEEP_IMAGES:-10}  # Keep last N images
KEEP_CHARTS=${KEEP_CHARTS:-10}   # Keep last N charts
KEEP_DAYS=${KEEP_DAYS:-30}        # Keep resources older than N days

# Function to cleanup old images from GitLab registry
cleanup_images() {
    echo ""
    echo "Cleaning up old images from GitLab registry..."
    
    if [ -z "$CI_REGISTRY" ] || [ -z "$CI_REGISTRY_USER" ] || [ -z "$CI_REGISTRY_PASSWORD" ]; then
        echo "WARNING: GitLab registry credentials not set, skipping image cleanup"
        return
    fi
    
    # Login to registry
    echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY" || {
        echo "ERROR: Failed to login to registry"
        return
    }
    
    # List and cleanup old images (requires GitLab API)
    echo "Image cleanup requires GitLab API access"
    echo "Use GitLab's container registry cleanup policies for automated cleanup"
}

# Function to cleanup old Helm charts
cleanup_charts() {
    echo ""
    echo "Cleaning up old Helm charts..."
    
    for repo_dir in "${ROOT_DIR}"/helm-repos/*; do
        if [ -d "$repo_dir" ]; then
            repo_name=$(basename "$repo_dir")
            echo "  Processing repository: ${repo_name}"
            
            # Count charts
            chart_count=$(find "$repo_dir" -name "*.tgz" | wc -l)
            echo "    Found ${chart_count} charts"
            
            if [ "$chart_count" -gt "$KEEP_CHARTS" ]; then
                # Sort by modification time and keep only latest N
                find "$repo_dir" -name "*.tgz" -type f -printf '%T@ %p\n' | \
                    sort -rn | \
                    tail -n +$((KEEP_CHARTS + 1)) | \
                    cut -d' ' -f2- | \
                    xargs rm -f || true
                
                echo "    Removed old charts, keeping latest ${KEEP_CHARTS}"
                
                # Update index
                if [ -f "${repo_dir}/index.yaml" ]; then
                    helm repo index "$repo_dir" --url "file://${repo_dir}" || true
                    echo "    Updated repository index"
                fi
            fi
        fi
    done
}

# Function to cleanup old Kubernetes resources
cleanup_k8s_resources() {
    echo ""
    echo "Cleaning up old Kubernetes resources..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "WARNING: kubectl not found, skipping Kubernetes cleanup"
        return
    fi
    
    # Cleanup completed jobs older than KEEP_DAYS
    echo "  Cleaning up old completed jobs..."
    kubectl get jobs --all-namespaces -o json | \
        jq -r '.items[] | select(.status.completionTime != null) | select((.status.completionTime | fromdateiso8601) < (now - ('"$KEEP_DAYS"' * 86400))) | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read -r namespace name; do
            kubectl delete job "$name" -n "$namespace" --ignore-not-found=true || true
        done
    
    # Cleanup old pods in completed/failed state
    echo "  Cleaning up old completed/failed pods..."
    kubectl get pods --all-namespaces --field-selector=status.phase!=Running -o json | \
        jq -r '.items[] | select(.status.startTime != null) | select((.status.startTime | fromdateiso8601) < (now - ('"$KEEP_DAYS"' * 86400))) | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read -r namespace name; do
            kubectl delete pod "$name" -n "$namespace" --ignore-not-found=true || true
        done
}

# Function to cleanup old Helm releases
cleanup_helm_releases() {
    echo ""
    echo "Cleaning up old Helm releases..."
    
    if ! command -v helm &> /dev/null; then
        echo "WARNING: helm not found, skipping Helm release cleanup"
        return
    fi
    
    # List all namespaces
    for namespace in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        if [[ "$namespace" =~ ^nova- ]]; then
            echo "  Processing namespace: ${namespace}"
            
            # Get all releases in namespace
            releases=$(helm list -n "$namespace" -q 2>/dev/null || echo "")
            
            for release in $releases; do
                # Get release history
                history_count=$(helm history "$release" -n "$namespace" --output json 2>/dev/null | jq 'length' || echo "0")
                
                if [ "$history_count" -gt "$KEEP_CHARTS" ]; then
                    # Get old revisions to delete
                    old_revisions=$(helm history "$release" -n "$namespace" --output json 2>/dev/null | \
                        jq -r '.[] | select(.status == "superseded") | .revision' | \
                        head -n -$KEEP_CHARTS)
                    
                    for revision in $old_revisions; do
                        echo "    Deleting old revision ${revision} of ${release}"
                        helm delete "$release" --namespace "$namespace" --keep-history || true
                    done
                fi
            done
        fi
    done
}

# Function to cleanup old logs
cleanup_logs() {
    echo ""
    echo "Cleaning up old log files..."
    
    # Cleanup CI/CD logs older than KEEP_DAYS
    find "${ROOT_DIR}" -name "*.log" -type f -mtime +$KEEP_DAYS -delete || true
    echo "  Removed log files older than ${KEEP_DAYS} days"
}

# Main cleanup execution
echo ""
echo "Cleanup Configuration:"
echo "  Keep images: ${KEEP_IMAGES}"
echo "  Keep charts: ${KEEP_CHARTS}"
echo "  Keep days: ${KEEP_DAYS}"
echo ""

# Run cleanup functions
cleanup_charts
cleanup_logs

# Optional: Kubernetes cleanup (requires kubectl access)
read -p "Run Kubernetes cleanup? [y/N]: " RUN_K8S_CLEANUP
if [[ "$RUN_K8S_CLEANUP" =~ ^[Yy]$ ]]; then
    cleanup_k8s_resources
    cleanup_helm_releases
fi

# Optional: Image cleanup (requires registry access)
read -p "Run image cleanup? [y/N]: " RUN_IMAGE_CLEANUP
if [[ "$RUN_IMAGE_CLEANUP" =~ ^[Yy]$ ]]; then
    cleanup_images
fi

echo ""
echo "=========================================="
echo "Cleanup Complete"
echo "=========================================="
