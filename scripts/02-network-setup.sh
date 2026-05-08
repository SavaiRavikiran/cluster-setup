#!/bin/bash

# Script: 02-network-setup.sh
# Description: Setup Kubernetes network layer (Cilium, Envoy, Nginx Ingress, MetalLB)
# Components: 2.1, 2.2, 2.9

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Kubernetes Network Setup"
echo "=========================================="

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace cilium-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f -

# 2.1 - Cilium CNI Setup
echo ""
echo "Setting up Cilium CNI..."
if [ ! -f "$ROOT_DIR/cluster/cilium/cilium-values.yaml" ]; then
    echo "Creating default Cilium values..."
    mkdir -p "$ROOT_DIR/cluster/cilium"
    cat > "$ROOT_DIR/cluster/cilium/cilium-values.yaml" <<EOF
operator:
  replicas: 2

hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true

ipam:
  mode: kubernetes

kubeProxyReplacement: strict
EOF
fi

helm repo add cilium https://helm.cilium.io/ || true
helm repo update
helm upgrade --install cilium cilium/cilium \
    --namespace cilium-system \
    --values "$ROOT_DIR/cluster/cilium/cilium-values.yaml" \
    --wait

echo "Waiting for Cilium to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=cilium -n cilium-system --timeout=300s

# Envoy Proxy Setup (as sidecar or gateway)
echo ""
echo "Setting up Envoy Proxy..."
kubectl create namespace envoy-system --dry-run=client -o yaml | kubectl apply -f -

# Install Envoy Gateway
helm repo add envoy-gateway https://envoyproxy.github.io/gateway-helm || true
helm repo update
helm upgrade --install envoy-gateway envoy-gateway/envoy-gateway \
    --namespace envoy-system \
    --create-namespace \
    --wait || echo "Envoy Gateway installation may require additional configuration"

# 2.2 - Nginx Ingress Controller
echo ""
echo "Setting up Nginx Ingress Controller..."
if [ ! -f "$ROOT_DIR/cluster/nginx-ingress/nginx-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/cluster/nginx-ingress"
    cat > "$ROOT_DIR/cluster/nginx-ingress/nginx-values.yaml" <<EOF
controller:
  replicaCount: 2
  service:
    type: LoadBalancer
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
EOF
fi

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --values "$ROOT_DIR/cluster/nginx-ingress/nginx-values.yaml" \
    --wait

echo "Waiting for Nginx Ingress to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s

# 2.9 - MetalLB Load Balancer
echo ""
echo "Setting up MetalLB..."
if [ ! -f "$ROOT_DIR/cluster/metallb/metallb-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/cluster/metallb"
    cat > "$ROOT_DIR/cluster/metallb/metallb-values.yaml" <<EOF
controller:
  tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Exists"
      effect: "NoSchedule"
speaker:
  tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Exists"
      effect: "NoSchedule"
EOF
fi

helm repo add metallb https://metallb.github.io/metallb || true
helm repo update
helm upgrade --install metallb metallb/metallb \
    --namespace metallb-system \
    --values "$ROOT_DIR/cluster/metallb/metallb-values.yaml" \
    --wait

echo "Waiting for MetalLB to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=metallb -n metallb-system --timeout=300s

# Create MetalLB IP Pool (user needs to configure IP range)
echo ""
echo "Creating MetalLB IP Pool configuration..."
cat > "$ROOT_DIR/cluster/metallb/ip-pool.yaml" <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  # TODO: Replace with your IP range
  - 192.168.1.100-192.168.1.200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF

echo ""
echo "=========================================="
echo "Network Setup Complete"
echo "=========================================="
echo ""
echo "IMPORTANT: Update the IP range in cluster/metallb/ip-pool.yaml"
echo "Then apply it with: kubectl apply -f cluster/metallb/ip-pool.yaml"
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n cilium-system"
echo "  kubectl get pods -n ingress-nginx"
echo "  kubectl get pods -n metallb-system"
