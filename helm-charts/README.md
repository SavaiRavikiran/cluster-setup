# Local Helm Charts Repository

This directory contains all Helm charts for the cluster infrastructure. All charts are stored locally to avoid dependency on remote Helm repositories.

## Structure

```
helm-charts/
├── cluster/              # Cluster infrastructure charts
│   ├── cilium/
│   ├── nginx-ingress/
│   ├── metallb/
│   └── nfs/
├── monitoring/           # Monitoring stack charts
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   └── alertmanager/
└── novaridium/           # Application charts
    ├── postgresql/
    ├── minio/
    ├── milvus/
    └── ...
```

## Usage

### Package a Chart
```bash
helm package helm-charts/cluster/cilium
```

### Create Index
```bash
helm repo index helm-charts/ --url https://your-gitlab.com/helm-charts
```

### Add Local Repo
```bash
helm repo add local-charts file://$(pwd)/helm-charts
helm repo update
```

## CI/CD Integration

The CI/CD pipeline automatically uses these local charts instead of remote repositories.
