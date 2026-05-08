#!/bin/bash

# Script to deploy all components to an environment
# Usage: ./deploy-all.sh <environment> [component-type]
# Example: ./deploy-all.sh dev cluster

set -e

ENVIRONMENT="${1:-dev}"
COMPONENT_TYPE="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=========================================="
echo "Deploying all components to ${ENVIRONMENT}"
echo "Component Type: ${COMPONENT_TYPE}"
echo "=========================================="

# Function to deploy a component
deploy_component() {
    local component=$1
    local component_type=$2
    local env=$3
    
    echo ""
    echo "Deploying ${component_type}/${component} to ${env}..."
    
    # This would trigger the GitLab CI/CD job
    # In a real scenario, you might use GitLab API or gitlab-ci-local
    echo "Triggering deployment job: deploy:${component_type}:${component}:${env}"
    
    # Example using GitLab API (requires GITLAB_TOKEN)
    if [ -n "$GITLAB_TOKEN" ] && [ -n "$CI_PROJECT_ID" ]; then
        curl --request POST \
          --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
          --form "ref=${([ "$env" = "dev" ] && echo "develop") || ([ "$env" = "staging" ] && echo "main") || ([ "$env" = "production" ] && echo "tags")}" \
          --form "variables[COMPONENT]=${component}" \
          --form "variables[ENVIRONMENT]=${env}" \
          --form "variables[COMPONENT_TYPE]=${component_type}" \
          "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/pipeline" || true
    else
        echo "GITLAB_TOKEN and CI_PROJECT_ID not set. Skipping API call."
        echo "Please trigger the deployment manually from GitLab UI."
    fi
}

# Deploy cluster components
if [ "$COMPONENT_TYPE" = "all" ] || [ "$COMPONENT_TYPE" = "cluster" ]; then
    echo ""
    echo "=== Cluster Components ==="
    for component in cilium nginx-ingress metallb nfs; do
        if [ -d "${ROOT_DIR}/cluster/${component}" ]; then
            deploy_component "$component" "cluster" "$ENVIRONMENT"
        fi
    done
fi

# Deploy monitoring components
if [ "$COMPONENT_TYPE" = "all" ] || [ "$COMPONENT_TYPE" = "monitoring" ]; then
    echo ""
    echo "=== Monitoring Components ==="
    for component in prometheus grafana loki alertmanager metrics-server; do
        if [ -d "${ROOT_DIR}/monitoring/${component}" ]; then
            deploy_component "$component" "monitoring" "$ENVIRONMENT"
        fi
    done
fi

# Deploy novaridium components
if [ "$COMPONENT_TYPE" = "all" ] || [ "$COMPONENT_TYPE" = "novaridium" ]; then
    echo ""
    echo "=== Novaridium Components ==="
    for component in postgresql minio milvus airbyte flyte ollama openfga openspg pgadmin novaridium discomine validator chat-mcp; do
        if [ -d "${ROOT_DIR}/novaridium/${component}" ]; then
            deploy_component "$component" "novaridium" "$ENVIRONMENT"
        fi
    done
fi

echo ""
echo "=========================================="
echo "Deployment trigger complete"
echo "Check GitLab CI/CD pipelines for status"
echo "=========================================="
