#!/bin/bash

# Script: 06-novaridium-setup.sh
# Description: Setup all Novaridium components
# Component: 4

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Novaridium Components Setup"
echo "=========================================="

# Create namespace
kubectl create namespace novaridium --dry-run=client -o yaml | kubectl apply -f -

# 4.7 - PostgreSQL Setup
echo ""
echo "Setting up PostgreSQL..."
if [ ! -f "$ROOT_DIR/novaridium/postgresql/postgresql-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/postgresql"
    cat > "$ROOT_DIR/novaridium/postgresql/postgresql-values.yaml" <<EOF
auth:
  postgresPassword: "changeme" # TODO: Change password
  database: "novaridium"

primary:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: nfs-client
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

readReplicas:
  replicaCount: 1
EOF
fi

helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

echo "PostgreSQL configuration created. Install with:"
echo "helm upgrade --install postgresql bitnami/postgresql --namespace novaridium --values novaridium/postgresql/postgresql-values.yaml"

# 4.6 - PgAdmin Setup
echo ""
echo "Setting up PgAdmin..."
if [ ! -f "$ROOT_DIR/novaridium/pgadmin/pgadmin-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/pgadmin"
    cat > "$ROOT_DIR/novaridium/pgadmin/pgadmin-values.yaml" <<EOF
env:
  email: admin@example.com # TODO: Change email
  password: admin # TODO: Change password

persistence:
  enabled: true
  size: 5Gi
  storageClass: nfs-client

service:
  type: LoadBalancer

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
EOF
fi

echo "PgAdmin configuration created. Install with:"
echo "helm upgrade --install pgadmin runix/pgadmin4 --namespace novaridium --values novaridium/pgadmin/pgadmin-values.yaml"

# 4.9 - MinIO Setup
echo ""
echo "Setting up MinIO..."
if [ ! -f "$ROOT_DIR/novaridium/minio/minio-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/minio"
    cat > "$ROOT_DIR/novaridium/minio/minio-values.yaml" <<EOF
mode: distributed
replicas: 4

auth:
  rootUser: minioadmin # TODO: Change
  rootPassword: minioadmin # TODO: Change

persistence:
  enabled: true
  size: 100Gi
  storageClass: nfs-client

service:
  type: LoadBalancer

resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
EOF
fi

helm repo add minio https://charts.min.io || true
helm repo update

echo "MinIO configuration created. Install with:"
echo "helm upgrade --install minio minio/minio --namespace novaridium --values novaridium/minio/minio-values.yaml"

# 4.8 - Milvus Setup
echo ""
echo "Setting up Milvus..."
if [ ! -f "$ROOT_DIR/novaridium/milvus/milvus-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/milvus"
    cat > "$ROOT_DIR/novaridium/milvus/milvus-values.yaml" <<EOF
mode: cluster

etcd:
  persistence:
    enabled: true
    size: 20Gi
    storageClass: nfs-client

minio:
  enabled: false # Use external MinIO

externalS3:
  enabled: true
  host: minio.novaridium.svc.cluster.local
  port: 9000
  accessKey: minioadmin # TODO: Update
  secretKey: minioadmin # TODO: Update
  bucketName: milvus-bucket
  useSSL: false

pulsar:
  enabled: true
  persistence:
    enabled: true
    size: 20Gi
    storageClass: nfs-client

standalone:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: nfs-client

resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
EOF
fi

helm repo add milvus https://milvus-io.github.io/milvus-helm || true
helm repo update

echo "Milvus configuration created. Install with:"
echo "helm upgrade --install milvus milvus/milvus --namespace novaridium --values novaridium/milvus/milvus-values.yaml"

# 4.1 - Airbyte Setup
echo ""
echo "Setting up Airbyte..."
if [ ! -f "$ROOT_DIR/novaridium/airbyte/airbyte-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/airbyte"
    cat > "$ROOT_DIR/novaridium/airbyte/airbyte-values.yaml" <<EOF
server:
  replicas: 2
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

worker:
  replicas: 2
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "2000m"

postgresql:
  enabled: true
  persistence:
    enabled: true
    size: 20Gi
    storageClass: nfs-client

minio:
  enabled: true
  persistence:
    enabled: true
    size: 50Gi
    storageClass: nfs-client
EOF
fi

helm repo add airbyte https://airbytehq.github.io/helm-charts || true
helm repo update

echo "Airbyte configuration created. Install with:"
echo "helm upgrade --install airbyte airbyte/airbyte --namespace novaridium --values novaridium/airbyte/airbyte-values.yaml"

# 4.2 - Flyte Setup
echo ""
echo "Setting up Flyte..."
if [ ! -f "$ROOT_DIR/novaridium/flyte/flyte-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/flyte"
    cat > "$ROOT_DIR/novaridium/flyte/flyte-values.yaml" <<EOF
admin:
  replicas: 2
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

propeller:
  replicas: 2
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

database:
  host: postgresql.novaridium.svc.cluster.local
  port: 5432
  database: flyte
  username: postgres
  password: changeme # TODO: Update

# 4.2.1 - Flyte SSO Configuration
auth:
  enabled: true
  # TODO: Configure SSO settings
  # oauth:
  #   clientId: ""
  #   clientSecret: ""
  #   issuerUrl: ""
EOF
fi

helm repo add flyteorg https://flyteorg.github.io/flyte || true
helm repo update

echo "Flyte configuration created. Install with:"
echo "helm upgrade --install flyte flyteorg/flyte-binary --namespace novaridium --values novaridium/flyte/flyte-values.yaml"

# 4.3 - Ollama Setup
echo ""
echo "Setting up Ollama..."
if [ ! -f "$ROOT_DIR/novaridium/ollama/ollama-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/novaridium/ollama"
    cat > "$ROOT_DIR/novaridium/ollama/ollama-values.yaml" <<EOF
replicas: 1

service:
  type: LoadBalancer

# 4.3.1 - PV for Models
persistence:
  enabled: true
  size: 100Gi
  storageClass: nfs-client
  accessMode: ReadWriteOnce

resources:
  requests:
    memory: "8Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "4000m"

env:
  - name: OLLAMA_HOST
    value: "0.0.0.0"
  - name: OLLAMA_KEEP_ALIVE
    value: "24h"
  - name: OLLAMA_ORIGINS
    value: "*"
EOF
fi

# Create Ollama deployment manifest
cat > "$ROOT_DIR/novaridium/ollama/ollama-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: novaridium
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        - name: OLLAMA_KEEP_ALIVE
          value: "24h"
        - name: OLLAMA_ORIGINS
          value: "*"
        volumeMounts:
        - name: models-storage
          mountPath: /root/.ollama
        resources:
          requests:
            memory: "8Gi"
            cpu: "2000m"
          limits:
            memory: "16Gi"
            cpu: "4000m"
      volumes:
      - name: models-storage
        persistentVolumeClaim:
          claimName: ollama-models-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ollama-models-pvc
  namespace: novaridium
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-client
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: ollama
  ports:
  - port: 11434
    targetPort: 11434
EOF

echo "Ollama configuration created. Apply with:"
echo "kubectl apply -f novaridium/ollama/ollama-deployment.yaml"

# 4.4 - OpenFGA Setup
echo ""
echo "Setting up OpenFGA..."
mkdir -p "$ROOT_DIR/novaridium/openfga"
cat > "$ROOT_DIR/novaridium/openfga/openfga-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openfga
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: openfga
  template:
    metadata:
      labels:
        app: openfga
    spec:
      containers:
      - name: openfga
        image: openfga/openfga:latest
        ports:
        - containerPort: 8080
        env:
        - name: OPENFGA_DATASTORE_ENGINE
          value: postgres
        - name: OPENFGA_DATASTORE_URI
          value: "postgres://postgres:changeme@postgresql.novaridium.svc.cluster.local:5432/openfga?sslmode=disable"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: openfga
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: openfga
  ports:
  - port: 8080
    targetPort: 8080
EOF

# 4.5 - OpenSPG Setup
echo ""
echo "Setting up OpenSPG..."
mkdir -p "$ROOT_DIR/novaridium/openspg"
cat > "$ROOT_DIR/novaridium/openspg/openspg-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openspg
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: openspg
  template:
    metadata:
      labels:
        app: openspg
    spec:
      containers:
      - name: openspg
        image: openspg/openspg:latest # TODO: Update with correct image
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          value: "postgres://postgres:changeme@postgresql.novaridium.svc.cluster.local:5432/openspg?sslmode=disable"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: openspg
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: openspg
  ports:
  - port: 8080
    targetPort: 8080
EOF

# 4.10, 4.11, 4.12, 4.13 - Application Components
echo ""
echo "Creating application component templates..."

# Novaridium App
mkdir -p "$ROOT_DIR/novaridium/novaridium"
cat > "$ROOT_DIR/novaridium/novaridium/novaridium-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: novaridium
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: novaridium
  template:
    metadata:
      labels:
        app: novaridium
    spec:
      containers:
      - name: novaridium
        image: novaridium/novaridium:latest # TODO: Update with actual image
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: url
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: novaridium
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: novaridium
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Discomine
mkdir -p "$ROOT_DIR/novaridium/discomine"
cat > "$ROOT_DIR/novaridium/discomine/discomine-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: discomine
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: discomine
  template:
    metadata:
      labels:
        app: discomine
    spec:
      containers:
      - name: discomine
        image: discomine/discomine:latest # TODO: Update with actual image
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: discomine
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: discomine
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Validator App
mkdir -p "$ROOT_DIR/novaridium/validator"
cat > "$ROOT_DIR/novaridium/validator/validator-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: validator
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: validator
  template:
    metadata:
      labels:
        app: validator
    spec:
      containers:
      - name: validator
        image: validator/validator:latest # TODO: Update with actual image
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: validator
  namespace: novaridium
spec:
  type: ClusterIP
  selector:
    app: validator
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Chat MCP (Vectorization Service)
mkdir -p "$ROOT_DIR/novaridium/chat-mcp"
cat > "$ROOT_DIR/novaridium/chat-mcp/chat-mcp-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-mcp
  namespace: novaridium
spec:
  replicas: 2
  selector:
    matchLabels:
      app: chat-mcp
  template:
    metadata:
      labels:
        app: chat-mcp
    spec:
      containers:
      - name: chat-mcp
        image: chat-mcp/vectorization-service:latest # TODO: Update with actual image
        ports:
        - containerPort: 8080
        env:
        - name: MILVUS_HOST
          value: "milvus.novaridium.svc.cluster.local"
        - name: MILVUS_PORT
          value: "19530"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: chat-mcp
  namespace: novaridium
spec:
  type: LoadBalancer
  selector:
    app: chat-mcp
  ports:
  - port: 8080
    targetPort: 8080
EOF

echo ""
echo "=========================================="
echo "Novaridium Components Setup Complete"
echo "=========================================="
echo ""
echo "All component configurations have been created."
echo "Review and update image names, passwords, and configurations before deploying."
echo ""
echo "Deployment order (recommended):"
echo "1. PostgreSQL"
echo "2. MinIO"
echo "3. Milvus"
echo "4. Airbyte"
echo "5. Flyte"
echo "6. Ollama"
echo "7. OpenFGA, OpenSPG"
echo "8. Application components (Novaridium, Discomine, Validator, Chat MCP)"
echo ""
echo "Use the helm commands or kubectl apply commands shown above for each component."
