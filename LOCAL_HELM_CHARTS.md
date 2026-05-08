# Local Helm Charts Repository

## Overview

All Helm charts are now stored locally in this repository instead of depending on remote Helm repositories. This provides:

- ✅ **No external dependencies**: All charts are version-controlled in Git
- ✅ **Offline deployments**: Deploy without internet access
- ✅ **Reproducibility**: Exact versions are tracked in Git
- ✅ **Air-gapped support**: Works in isolated environments
- ✅ **Faster deployments**: No need to pull from remote repos

## Structure

```
helm-charts/              # Local Helm charts repository
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

component-directories/     # Component-specific values files
├── cluster/
│   ├── cilium/cilium-values.yaml
│   ├── nginx-ingress/nginx-ingress-values.yaml
│   └── ...
├── monitoring/
│   ├── prometheus/prometheus-values.yaml
│   └── ...
└── novaridium/
    ├── postgresql/postgresql-values.yaml
    └── ...
```

## How It Works

### 1. Values Files
All component values files are stored in their respective directories:
- `cluster/<component>/<component>-values.yaml`
- `monitoring/<component>/<component>-values.yaml`
- `novaridium/<component>/<component>-values.yaml`

### 2. CI/CD Integration
The CI/CD pipeline automatically:
- Looks for local charts in `helm-charts/` directory
- Falls back to packaged charts (`*.tgz` files)
- Uses values files from component directories
- No remote Helm repository dependencies

### 3. Chart Packaging (Optional)
If you want to package charts for distribution:

```bash
# Package all charts
./scripts/07-package-helm-charts.sh

# This creates:
# - helm-charts/*.tgz (packaged charts)
# - helm-charts/index.yaml (repository index)
```

## Using Local Charts

### In CI/CD Pipeline
The pipeline automatically uses local charts. No configuration needed!

### Manual Deployment
```bash
# Option 1: Use values file directly (if chart is in helm-charts/)
helm upgrade --install postgresql helm-charts/novaridium/postgresql \
  --namespace novaridium \
  -f novaridium/postgresql/postgresql-values.yaml

# Option 2: Use packaged chart
helm repo add local-charts file://$(pwd)/helm-charts
helm repo update
helm upgrade --install postgresql local-charts/postgresql \
  --namespace novaridium \
  -f novaridium/postgresql/postgresql-values.yaml
```

## Adding New Charts

### Method 1: Copy from Remote Repository
```bash
# Pull chart from remote
helm pull bitnami/postgresql --untar

# Copy to local repository
cp -r postgresql helm-charts/novaridium/

# Update values file
vim novaridium/postgresql/postgresql-values.yaml
```

### Method 2: Create Custom Chart
```bash
# Create new chart
helm create helm-charts/novaridium/my-component

# Customize chart
vim helm-charts/novaridium/my-component/Chart.yaml
vim helm-charts/novaridium/my-component/values.yaml

# Create values file
vim novaridium/my-component/my-component-values.yaml
```

## Component Values Files

All components now have complete values files:

### Cluster Components
- ✅ `cluster/cilium/cilium-values.yaml`
- ✅ `cluster/nginx-ingress/nginx-ingress-values.yaml`
- ✅ `cluster/metallb/metallb-values.yaml`
- ✅ `cluster/nfs/nfs-values.yaml`

### Monitoring Components
- ✅ `monitoring/prometheus/prometheus-values.yaml`
- ✅ `monitoring/grafana/grafana-values.yaml`
- ✅ `monitoring/loki/loki-values.yaml`
- ✅ `monitoring/alertmanager/alertmanager-values.yaml`

### Novaridium Components
- ✅ `novaridium/postgresql/postgresql-values.yaml`
- ✅ `novaridium/minio/minio-values.yaml`
- ✅ `novaridium/milvus/milvus-values.yaml`
- ✅ `novaridium/airbyte/airbyte-values.yaml`
- ✅ `novaridium/flyte/flyte-values.yaml`
- ✅ `novaridium/ollama/ollama-values.yaml`
- ✅ `novaridium/openfga/openfga-values.yaml`
- ✅ `novaridium/openspg/openspg-values.yaml`
- ✅ `novaridium/pgadmin/pgadmin-values.yaml`
- ✅ `novaridium/novaridium/novaridium-values.yaml`
- ✅ `novaridium/discomine/discomine-values.yaml`
- ✅ `novaridium/validator/validator-values.yaml`
- ✅ `novaridium/chat-mcp/chat-mcp-values.yaml`
- ✅ `novaridium/prefect/prefect-values.yaml`

## Benefits

### 1. Version Control
- All chart versions are tracked in Git
- Easy to see what changed and when
- Rollback to any previous version

### 2. Security
- No external dependencies to trust
- All charts reviewed before use
- No risk of supply chain attacks

### 3. Performance
- Faster deployments (no network calls)
- No rate limiting issues
- Works in low-bandwidth environments

### 4. Compliance
- Meets air-gapped requirements
- Audit trail in Git
- Reproducible builds

## Migration from Remote Repos

If you were using remote Helm repositories:

1. **Remove remote repo references** from CI/CD (already done)
2. **Copy charts** to `helm-charts/` directory
3. **Update values files** with your customizations
4. **Test deployments** in dev environment
5. **Deploy to production**

## Maintenance

### Updating Charts
1. Pull new version from remote (if needed)
2. Copy to `helm-charts/`
3. Test in dev environment
4. Update values files if needed
5. Commit to Git

### Versioning
- Charts are versioned in Git
- Use Git tags for releases
- CI/CD uses specific versions

## Troubleshooting

### Chart Not Found
```
ERROR: Local Helm chart not found for <component>
```

**Solution**: 
- Ensure chart exists in `helm-charts/<category>/<component>/`
- Or package chart using `./scripts/07-package-helm-charts.sh`

### Values File Not Found
```
ERROR: Values file not found: <path>
```

**Solution**:
- Ensure values file exists in component directory
- Check file naming: `<component>-values.yaml`

### Chart Validation Failed
```
ERROR: Chart validation failed
```

**Solution**:
- Check Chart.yaml exists and is valid
- Verify all required files are present
- Run `helm lint` on the chart

## Next Steps

1. **Review values files**: Update with your specific configurations
2. **Package charts** (optional): Run `./scripts/07-package-helm-charts.sh`
3. **Test deployments**: Deploy to dev environment first
4. **Update CI/CD**: Already configured to use local charts
5. **Deploy**: Use CI/CD pipeline or manual deployment

All components are now ready for deployment with local Helm charts!
