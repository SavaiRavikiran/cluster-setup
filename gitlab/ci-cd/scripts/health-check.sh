#!/bin/bash

# Health check script for deployed components
# Usage: ./health-check.sh [namespace] [component]

set -e

NAMESPACE="${1:-all}"
COMPONENT="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=========================================="
echo "Health Check for Components"
echo "Namespace: ${NAMESPACE}"
echo "Component: ${COMPONENT}"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

# Function to check component health
check_component_health() {
    local ns=$1
    local comp=$2
    
    echo ""
    echo "Checking ${comp} in namespace ${ns}..."
    
    # Check if namespace exists
    if ! kubectl get namespace "$ns" &> /dev/null; then
        echo "  ❌ Namespace ${ns} does not exist"
        return 1
    fi
    
    # Check deployments
    if kubectl get deployment -n "$ns" | grep -q "$comp"; then
        echo "  ✓ Deployment exists"
        
        # Check deployment status
        READY=$(kubectl get deployment "$comp" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        DESIRED=$(kubectl get deployment "$comp" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$READY" = "$DESIRED" ] && [ "$READY" != "0" ]; then
            echo "  ✓ Deployment is ready (${READY}/${DESIRED} replicas)"
        else
            echo "  ⚠️  Deployment not fully ready (${READY}/${DESIRED} replicas)"
        fi
    else
        echo "  ⚠️  Deployment not found"
    fi
    
    # Check pods
    PODS=$(kubectl get pods -n "$ns" -l app="$comp" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$PODS" ]; then
        for pod in $PODS; do
            STATUS=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            if [ "$STATUS" = "Running" ]; then
                echo "  ✓ Pod ${pod} is Running"
            else
                echo "  ⚠️  Pod ${pod} status: ${STATUS}"
            fi
        done
    fi
    
    # Check services
    if kubectl get service -n "$ns" | grep -q "$comp"; then
        echo "  ✓ Service exists"
    fi
    
    # Check ingress
    if kubectl get ingress -n "$ns" | grep -q "$comp"; then
        echo "  ✓ Ingress exists"
    fi
}

# Check all namespaces
if [ "$NAMESPACE" = "all" ]; then
    NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E "(cluster-infra|monitoring|novaridium|dev|staging|production)" || echo "")
    
    for ns in $NAMESPACES; do
        if [ "$COMPONENT" = "all" ]; then
            # Check all components in namespace
            COMPONENTS=$(kubectl get deployments -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
            for comp in $COMPONENTS; do
                check_component_health "$ns" "$comp"
            done
        else
            check_component_health "$ns" "$COMPONENT"
        fi
    done
else
    if [ "$COMPONENT" = "all" ]; then
        COMPONENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        for comp in $COMPONENTS; do
            check_component_health "$NAMESPACE" "$comp"
        done
    else
        check_component_health "$NAMESPACE" "$COMPONENT"
    fi
fi

echo ""
echo "=========================================="
echo "Health check complete"
echo "=========================================="
