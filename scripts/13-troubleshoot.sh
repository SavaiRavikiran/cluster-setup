#!/bin/bash

# Troubleshooting Helper Script
# Helps diagnose and fix common issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

echo "=========================================="
echo "  Nova Cluster - Troubleshooting Helper"
echo "=========================================="
echo ""

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local issues=0
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found"
        issues=$((issues+1))
    else
        print_success "kubectl found"
        if ! kubectl cluster-info &> /dev/null; then
            print_error "kubectl not configured or cluster unreachable"
            issues=$((issues+1))
        else
            print_success "kubectl connected to cluster"
        fi
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm not found"
        issues=$((issues+1))
    else
        print_success "helm found"
    fi
    
    # Check docker (optional)
    if ! command -v docker &> /dev/null; then
        print_warning "docker not found (optional for image operations)"
    else
        print_success "docker found"
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        print_success "All prerequisites met"
        return 0
    else
        print_error "Found $issues issues"
        return 1
    fi
}

# Check component deployment
check_component() {
    local component=$1
    local env=${2:-dev}
    local namespace="nova-${env}${component}"
    
    print_info "Checking $component in $env..."
    echo ""
    
    # Check namespace
    if kubectl get namespace "$namespace" &> /dev/null; then
        print_success "Namespace exists: $namespace"
    else
        print_error "Namespace not found: $namespace"
        return 1
    fi
    
    # Check deployments
    echo ""
    print_info "Deployments:"
    kubectl get deployments -n "$namespace" || print_warning "No deployments found"
    
    # Check pods
    echo ""
    print_info "Pods:"
    kubectl get pods -n "$namespace" || print_warning "No pods found"
    
    # Check services
    echo ""
    print_info "Services:"
    kubectl get services -n "$namespace" || print_warning "No services found"
    
    # Check events
    echo ""
    print_info "Recent events:"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' | tail -5 || true
    
    # Check Helm release
    echo ""
    print_info "Helm release:"
    helm list -n "$namespace" || print_warning "No Helm release found"
}

# Diagnose pod issues
diagnose_pod() {
    local namespace=$1
    local pod=$2
    
    print_info "Diagnosing pod: $pod in $namespace"
    echo ""
    
    # Describe pod
    kubectl describe pod "$pod" -n "$namespace" | grep -A 20 "Events:" || true
    
    # Get logs
    echo ""
    print_info "Pod logs (last 50 lines):"
    kubectl logs "$pod" -n "$namespace" --tail=50 || true
}

# Fix common issues
fix_issues() {
    local component=$1
    local env=${2:-dev}
    local namespace="nova-${env}${component}"
    
    print_info "Attempting to fix issues for $component..."
    echo ""
    
    # Restart deployment
    if kubectl get deployment "$component" -n "$namespace" &> /dev/null; then
        print_info "Restarting deployment..."
        kubectl rollout restart deployment/"$component" -n "$namespace"
        kubectl rollout status deployment/"$component" -n "$namespace" --timeout=300s || true
    fi
    
    # Delete stuck pods
    print_info "Checking for stuck pods..."
    for pod in $(kubectl get pods -n "$namespace" -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}'); do
        if [ -n "$pod" ]; then
            print_warning "Deleting stuck pod: $pod"
            kubectl delete pod "$pod" -n "$namespace" --grace-period=0 --force || true
        fi
    done
}

# Main menu
main() {
    echo "Select troubleshooting option:"
    echo "1) Check prerequisites"
    echo "2) Check component deployment"
    echo "3) Diagnose pod issues"
    echo "4) Fix common issues"
    echo "5) Check cluster health"
    echo "6) View component logs"
    echo "7) Check resource usage"
    echo ""
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1)
            check_prerequisites
            ;;
        2)
            read -p "Enter component name: " component
            read -p "Enter environment [dev/staging/prod]: " env
            check_component "$component" "$env"
            ;;
        3)
            read -p "Enter namespace: " namespace
            read -p "Enter pod name: " pod
            diagnose_pod "$namespace" "$pod"
            ;;
        4)
            read -p "Enter component name: " component
            read -p "Enter environment [dev/staging/prod]: " env
            fix_issues "$component" "$env"
            ;;
        5)
            "$ROOT_DIR/cli/nova" health
            ;;
        6)
            read -p "Enter component name: " component
            read -p "Enter environment [dev/staging/prod]: " env
            "$ROOT_DIR/cli/nova" logs "$component" "$env"
            ;;
        7)
            print_info "Resource usage:"
            kubectl top nodes || print_warning "Metrics server not available"
            echo ""
            for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | grep "^nova-"); do
                echo "Namespace: $ns"
                kubectl top pods -n "$ns" 2>/dev/null || true
            done
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

main
