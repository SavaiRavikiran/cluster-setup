#!/bin/bash

# Script: 05-monitoring-setup.sh
# Description: Setup monitoring stack (Prometheus, AlertManager, Grafana, Loki, Metrics Server, Exporters)
# Components: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Monitoring Stack Setup"
echo "=========================================="

# Create namespaces
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace loki --dry-run=client -o yaml | kubectl apply -f -

# 3.4 - Metrics Server
echo ""
echo "Setting up Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml || \
    kubectl apply -f "$ROOT_DIR/monitoring/metrics-server/metrics-server.yaml"

# Create metrics-server manifest if URL fails
if [ ! -f "$ROOT_DIR/monitoring/metrics-server/metrics-server.yaml" ]; then
    mkdir -p "$ROOT_DIR/monitoring/metrics-server"
    cat > "$ROOT_DIR/monitoring/metrics-server/metrics-server.yaml" <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.3
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
          - --kubelet-use-node-status-port
          - --metric-resolution=15s
        ports:
        - name: https
          containerPort: 4443
          protocol: TCP
EOF
fi

# 3.1 - Prometheus Setup
echo ""
echo "Setting up Prometheus..."
if [ ! -f "$ROOT_DIR/monitoring/prometheus/prometheus-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/monitoring/prometheus"
    cat > "$ROOT_DIR/monitoring/prometheus/prometheus-values.yaml" <<EOF
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: nfs-client
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false

alertmanager:
  enabled: true
  alertmanagerSpec:
    replicas: 2
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: nfs-client
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    resources:
      requests:
        memory: "512Mi"
        cpu: "200m"
      limits:
        memory: "1Gi"
        cpu: "500m"

grafana:
  enabled: true
  adminPassword: admin # TODO: Change this
  persistence:
    enabled: true
    storageClassName: nfs-client
    size: 10Gi
  service:
    type: LoadBalancer
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"

kube-state-metrics:
  enabled: true

nodeExporter:
  enabled: true

prometheusOperator:
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
EOF
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values "$ROOT_DIR/monitoring/prometheus/prometheus-values.yaml" \
    --wait

# 3.2 - AlertManager Configuration
echo ""
echo "Configuring AlertManager..."
mkdir -p "$ROOT_DIR/monitoring/alertmanager"

# AlertManager configuration
cat > "$ROOT_DIR/monitoring/alertmanager/alertmanager-config.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      # TODO: Configure SMTP settings
      # smtp_smarthost: 'smtp.example.com:587'
      # smtp_from: 'alerts@example.com'
      # smtp_auth_username: 'user'
      # smtp_auth_password: 'password'

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'

    receivers:
    - name: 'default'
      email_configs:
      - to: 'admin@example.com' # TODO: Update email
        send_resolved: true

    - name: 'critical-alerts'
      email_configs:
      - to: 'oncall@example.com' # TODO: Update email
        send_resolved: true
      # SNOW integration example (webhook)
      webhook_configs:
      - url: 'https://your-snow-instance.service-now.com/api/now/table/incident' # TODO: Update
        http_config:
          bearer_token: 'your-token' # TODO: Update

    - name: 'warning-alerts'
      email_configs:
      - to: 'team@example.com' # TODO: Update email
        send_resolved: true

    inhibit_rules:
      - source_match:
          severity: 'critical'
        target_match:
          severity: 'warning'
        equal: ['alertname', 'cluster', 'service']
EOF

echo "AlertManager configuration created. Update with your SMTP and SNOW settings, then apply:"
echo "kubectl apply -f monitoring/alertmanager/alertmanager-config.yaml"

# Alert rules
mkdir -p "$ROOT_DIR/monitoring/alertmanager/rules"
cat > "$ROOT_DIR/monitoring/alertmanager/rules/k8s-alerts.yaml" <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: k8s-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes
    interval: 30s
    rules:
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ \$labels.namespace }}/{{ \$labels.pod }} is crash looping"

    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ \$labels.instance }} has high memory usage"

    - alert: HighCPUUsage
      expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Node {{ \$labels.instance }} has high CPU usage"

    - alert: DiskSpaceLow
      expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ \$labels.instance }} has low disk space"
EOF

# 3.3 - Grafana Dashboards
echo ""
echo "Setting up Grafana dashboards..."
mkdir -p "$ROOT_DIR/monitoring/grafana/dashboards"

cat > "$ROOT_DIR/monitoring/grafana/dashboards/dashboard-config.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  kubernetes.json: |
    {
      "dashboard": {
        "title": "Kubernetes Cluster Monitoring",
        "tags": ["kubernetes"],
        "timezone": "browser",
        "panels": []
      }
    }
EOF

# 3.5 - Loki Stack Setup
echo ""
echo "Setting up Loki Stack..."
if [ ! -f "$ROOT_DIR/monitoring/loki/loki-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/monitoring/loki"
    cat > "$ROOT_DIR/monitoring/loki/loki-values.yaml" <<EOF
loki:
  persistence:
    enabled: true
    storageClassName: nfs-client
    size: 50Gi
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

promtail:
  enabled: true
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"

grafana:
  enabled: true
  adminPassword: admin # TODO: Change this
  persistence:
    enabled: true
    storageClassName: nfs-client
    size: 10Gi
  service:
    type: LoadBalancer

vector:
  enabled: true
  config:
    data_dir: /vector-data-dir
    api:
      enabled: true
      address: 0.0.0.0:8686
    sources:
      kubernetes_logs:
        type: kubernetes_logs
    sinks:
      loki:
        type: loki
        inputs:
          - kubernetes_logs
        endpoint: http://loki:3100
        labels:
          namespace: "{{ namespace }}"
          pod: "{{ pod }}"
          container: "{{ container }}"
EOF
fi

helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

echo "Loki configuration created. Install with:"
echo "helm upgrade --install loki grafana/loki-stack --namespace loki --values monitoring/loki/loki-values.yaml"

# 3.6 - Exporters Setup
echo ""
echo "Setting up Exporters..."

# Blackbox Exporter
mkdir -p "$ROOT_DIR/monitoring/exporters/blackbox"
cat > "$ROOT_DIR/monitoring/exporters/blackbox/blackbox-exporter.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blackbox-exporter
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blackbox-exporter
  template:
    metadata:
      labels:
        app: blackbox-exporter
    spec:
      containers:
      - name: blackbox-exporter
        image: prom/blackbox-exporter:latest
        ports:
        - containerPort: 9115
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: blackbox-exporter
  namespace: monitoring
spec:
  selector:
    app: blackbox-exporter
  ports:
  - port: 9115
    targetPort: 9115
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: blackbox-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: blackbox-exporter
  endpoints:
  - port: ""
    path: /metrics
EOF

# Node Exporter (usually included in kube-prometheus-stack)
echo "Node Exporter is included in kube-prometheus-stack"

# Airbyte Exporter
mkdir -p "$ROOT_DIR/monitoring/exporters/airbyte"
cat > "$ROOT_DIR/monitoring/exporters/airbyte/airbyte-exporter.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: airbyte-exporter
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: airbyte-exporter
  template:
    metadata:
      labels:
        app: airbyte-exporter
    spec:
      containers:
      - name: airbyte-exporter
        image: airbyte/airbyte-exporter:latest
        ports:
        - containerPort: 8080
        env:
        - name: AIRBYTE_API_URL
          value: "http://airbyte-api:8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: airbyte-exporter
  namespace: monitoring
spec:
  selector:
    app: airbyte-exporter
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: airbyte-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: airbyte-exporter
  endpoints:
  - port: ""
    path: /metrics
EOF

echo ""
echo "=========================================="
echo "Monitoring Stack Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Apply metrics-server: kubectl apply -f monitoring/metrics-server/metrics-server.yaml"
echo "2. Update AlertManager config with SMTP/SNOW settings"
echo "3. Apply AlertManager config: kubectl apply -f monitoring/alertmanager/alertmanager-config.yaml"
echo "4. Apply alert rules: kubectl apply -f monitoring/alertmanager/rules/k8s-alerts.yaml"
echo "5. Install Loki: helm upgrade --install loki grafana/loki-stack --namespace loki --values monitoring/loki/loki-values.yaml"
echo "6. Apply exporters: kubectl apply -f monitoring/exporters/"
echo ""
echo "Access Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
