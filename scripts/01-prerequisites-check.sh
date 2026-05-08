#!/bin/bash

# Script: 01-prerequisites-check.sh
# Description: Check all prerequisites before cluster setup
# Component: 2.0 - Nodes Pre-requisite Check

set -e

echo "=========================================="
echo "Kubernetes Cluster Prerequisites Check"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed: $(command -v $1)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

check_version() {
    local cmd=$1
    local min_version=$2
    local current_version=$($cmd --version 2>&1 | head -n1)
    echo -e "${GREEN}✓${NC} $cmd version: $current_version"
}

# Check kubectl
echo ""
echo "Checking kubectl..."
if check_command kubectl; then
    check_version kubectl "v1.24"
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
        kubectl get nodes
    else
        echo -e "${YELLOW}⚠${NC} Kubernetes cluster may not be configured"
    fi
else
    echo -e "${RED}ERROR: kubectl is required${NC}"
    exit 1
fi

# Check Helm
echo ""
echo "Checking Helm..."
if check_command helm; then
    check_version helm "v3"
    if helm version &> /dev/null; then
        echo -e "${GREEN}✓${NC} Helm is configured"
    fi
else
    echo -e "${RED}ERROR: Helm 3.x is required${NC}"
    exit 1
fi

# Check Ansible
echo ""
echo "Checking Ansible..."
if check_command ansible; then
    check_version ansible "2.9"
else
    echo -e "${YELLOW}⚠${NC} Ansible is not installed (optional but recommended)"
fi

# Check Docker (for GitLab Runner)
echo ""
echo "Checking Docker..."
if check_command docker; then
    check_version docker
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker daemon is running"
    else
        echo -e "${YELLOW}⚠${NC} Docker daemon may not be running"
    fi
else
    echo -e "${YELLOW}⚠${NC} Docker is not installed (required for GitLab Runner)"
fi

# Check network connectivity
echo ""
echo "Checking network connectivity..."
REQUIRED_URLS=(
    "https://pypi.python.org"
    "https://registry.ollama.com"
    "https://www.python.org/downloads"
)

for url in "${REQUIRED_URLS[@]}"; do
    if curl -s --connect-timeout 5 "$url" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $url is accessible"
    else
        echo -e "${YELLOW}⚠${NC} $url may not be accessible (check proxy settings)"
    fi
done

# Check node resources
echo ""
echo "Checking Kubernetes nodes..."
if kubectl get nodes &> /dev/null; then
    echo "Node Details:"
    kubectl get nodes -o wide
    echo ""
    echo "Node Resources:"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available yet"
else
    echo -e "${YELLOW}⚠${NC} Cannot access Kubernetes nodes"
fi

# Check required namespaces
echo ""
echo "Checking namespaces..."
REQUIRED_NAMESPACES=("kube-system" "default")
for ns in "${REQUIRED_NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Namespace $ns exists"
    else
        echo -e "${RED}✗${NC} Namespace $ns does not exist"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "Prerequisites Check Complete"
echo "=========================================="
echo ""
echo "If all checks passed, proceed with cluster setup."
echo "If any checks failed, please resolve them before continuing."
