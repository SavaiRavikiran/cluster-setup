#!/bin/bash

# Script: 03-core-infra-setup.sh
# Description: Setup core infrastructure (NFS, Vault, PKI, Helm repos)
# Components: 2.3, 2.4, 2.6, 2.7

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Core Infrastructure Setup"
echo "=========================================="

# 2.3 - NFS Storage Setup
echo ""
echo "Setting up NFS Storage..."
kubectl create namespace nfs-system --dry-run=client -o yaml | kubectl apply -f -

# Install NFS Subdir External Provisioner
if [ ! -f "$ROOT_DIR/cluster/nfs/nfs-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/cluster/nfs"
    cat > "$ROOT_DIR/cluster/nfs/nfs-values.yaml" <<EOF
nfs:
  server: # TODO: Set your NFS server IP or hostname
  path: /exports

storageClass:
  create: true
  name: nfs-client
  defaultClass: false
  allowVolumeExpansion: true
  reclaimPolicy: Delete
EOF
fi

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ || true
helm repo update

echo "NOTE: Update NFS server details in cluster/nfs/nfs-values.yaml before installation"
echo "Then run: helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --namespace nfs-system --values cluster/nfs/nfs-values.yaml"

# 2.4 - Helm Repository Setup
echo ""
echo "Setting up Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add loki https://grafana.github.io/loki/charts || true
helm repo add gitlab https://charts.gitlab.io || true
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo add airbyte https://airbytehq.github.io/helm-charts || true
helm repo add flyteorg https://flyteorg.github.io/flyte || true
helm repo add milvus https://milvus-io.github.io/milvus-helm || true
helm repo add minio https://charts.min.io || true
helm repo update

echo "Helm repositories configured:"
helm repo list

# 2.6 - Hashicorp Vault Setup
echo ""
echo "Setting up Hashicorp Vault..."
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

if [ ! -f "$ROOT_DIR/vault/config/vault-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/vault/config"
    cat > "$ROOT_DIR/vault/config/vault-values.yaml" <<EOF
server:
  ha:
    enabled: true
    replicas: 3
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: nfs-client
  auditStorage:
    enabled: true
    size: 5Gi
    storageClass: nfs-client

ui:
  enabled: true
  serviceType: LoadBalancer

injector:
  enabled: true
EOF
fi

helm repo add hashicorp https://helm.releases.hashicorp.com || true
helm repo update

echo "Installing Vault..."
helm upgrade --install vault hashicorp/vault \
    --namespace vault \
    --values "$ROOT_DIR/vault/config/vault-values.yaml" \
    --wait || echo "Vault installation may require additional configuration"

# Wait for Vault pods
echo "Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s || true

# 2.7 - PKI Setup
echo ""
echo "Setting up PKI configuration..."
mkdir -p "$ROOT_DIR/pki/ca" "$ROOT_DIR/pki/certs"

# Create PKI configuration script
cat > "$ROOT_DIR/pki/setup-pki.sh" <<'PKIEOF'
#!/bin/bash
# PKI Setup Script
# This script sets up Certificate Authority and generates certificates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/ca"
CERTS_DIR="$SCRIPT_DIR/certs"

mkdir -p "$CA_DIR" "$CERTS_DIR"

# Generate CA private key
if [ ! -f "$CA_DIR/ca-key.pem" ]; then
    openssl genrsa -out "$CA_DIR/ca-key.pem" 4096
    echo "Generated CA private key"
fi

# Generate CA certificate
if [ ! -f "$CA_DIR/ca.pem" ]; then
    openssl req -new -x509 -days 3650 -key "$CA_DIR/ca-key.pem" \
        -out "$CA_DIR/ca.pem" \
        -subj "/CN=Kubernetes CA/O=Kubernetes"
    echo "Generated CA certificate"
fi

# Create certificate generation helper
cat > "$CERTS_DIR/generate-cert.sh" <<'CERTEOF'
#!/bin/bash
# Usage: ./generate-cert.sh <name> <domain> [additional-domains...]

NAME=$1
DOMAIN=$2
shift 2
ADDITIONAL_DOMAINS=$@

if [ -z "$NAME" ] || [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <name> <domain> [additional-domains...]"
    exit 1
fi

CA_DIR="$(cd "$(dirname "$0")/../ca" && pwd)"
CERTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Generate private key
openssl genrsa -out "$CERTS_DIR/${NAME}-key.pem" 2048

# Create CSR config
cat > "$CERTS_DIR/${NAME}.conf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
EOF

# Add additional domains
i=2
for alt_domain in $ADDITIONAL_DOMAINS; do
    echo "DNS.$i = $alt_domain" >> "$CERTS_DIR/${NAME}.conf"
    i=$((i+1))
done

# Generate CSR
openssl req -new -key "$CERTS_DIR/${NAME}-key.pem" \
    -out "$CERTS_DIR/${NAME}.csr" \
    -subj "/CN=$DOMAIN" \
    -config "$CERTS_DIR/${NAME}.conf"

# Sign certificate
openssl x509 -req -in "$CERTS_DIR/${NAME}.csr" \
    -CA "$CA_DIR/ca.pem" \
    -CAkey "$CA_DIR/ca-key.pem" \
    -CAcreateserial \
    -out "$CERTS_DIR/${NAME}.pem" \
    -days 365 \
    -extensions v3_req \
    -extfile "$CERTS_DIR/${NAME}.conf"

echo "Generated certificate for $NAME ($DOMAIN)"
CERTEOF

chmod +x "$CERTS_DIR/generate-cert.sh"
echo "PKI setup complete. Use $CERTS_DIR/generate-cert.sh to generate certificates"
PKIEOF

chmod +x "$ROOT_DIR/pki/setup-pki.sh"
echo "PKI setup script created. Run: ./pki/setup-pki.sh"

# Create Kubernetes secrets for CA
echo ""
echo "Creating Kubernetes CA secret..."
kubectl create secret generic ca-certificate \
    --from-file=ca.crt="$ROOT_DIR/pki/ca/ca.pem" \
    --namespace kube-system \
    --dry-run=client -o yaml | kubectl apply -f - || echo "CA certificate not yet generated"

echo ""
echo "=========================================="
echo "Core Infrastructure Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure NFS server in cluster/nfs/nfs-values.yaml"
echo "2. Run: ./pki/setup-pki.sh to set up PKI"
echo "3. Initialize Vault: kubectl exec -it vault-0 -n vault -- vault operator init"
echo "4. Unseal Vault pods"
