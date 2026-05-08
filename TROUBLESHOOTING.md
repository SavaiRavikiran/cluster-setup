# Troubleshooting Guide

Common issues and their solutions.

## Issue: "Helm chart not found" or "Chart.yaml file is missing"

### Problem
The CLI finds a directory but it's not a valid Helm chart (missing Chart.yaml).

### Solution
The CLI now automatically falls back to remote Helm repositories. First, add the repositories:

```bash
# Add all Helm repositories
./cli/nova pull-charts

# Then deploy
./cli/nova deploy milvus dev
./cli/nova deploy postgresql dev
./cli/nova deploy cilium dev
```

The CLI will:
1. Check for local charts first
2. Validate that local charts have Chart.yaml
3. Automatically fall back to remote repositories if local charts are missing or invalid
4. Add required Helm repositories automatically

## Issue: "kubectl: command not found"

### Solution
Install kubectl:

**On macOS:**
```bash
brew install kubectl
```

**On Linux (Ubuntu/Debian):**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**On Lima:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Issue: "helm: command not found"

### Solution
Install Helm:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Issue: Read-only filesystem (Lima)

### Problem
Scripts can't write to the filesystem because it's mounted read-only.

### Solution
The scripts now handle this gracefully:
- They check if files are writable before trying to write
- Use temporary directories when needed
- Provide warnings instead of failing

For Lima specifically:
- Most operations work fine (reading files, deploying)
- Only scripts that need to write files will show warnings
- Use remote Helm repositories instead of local charts

## Issue: Component name not found

### Problem
Using a component name that doesn't match the directory structure.

### Solution
The CLI now maps common variations:
- `postgresql` or `postgres` → `postgresql` (finds `novaridium/postgresql/`)
- `minio` or `minio-operator` → `minio`

Use the correct name or let the CLI map it:
```bash
# Both work:
./cli/nova deploy postgresql dev
./cli/nova deploy postgres dev
```

## Issue: Values file not found

### Problem
Values file doesn't exist for the component.

### Solution
1. Check if the component has a values file:
   ```bash
   ls novaridium/<component>/<component>-values.yaml
   ls cluster/<component>/<component>-values.yaml
   ls monitoring/<component>/<component>-values.yaml
   ```

2. Create the values file if missing (copy from example or create new)

3. Use the correct component name (see component mapping above)

## Issue: Deployment fails

### Common Causes

1. **Kubernetes cluster not accessible**
   ```bash
   kubectl cluster-info
   ```

2. **Namespace creation fails**
   - Check RBAC permissions
   - Verify kubectl has proper access

3. **Helm chart issues**
   - Run validation first: `./cli/nova validate <component>`
   - Check values file syntax

4. **Resource constraints**
   - Check cluster resources: `kubectl top nodes`
   - Review resource requests in values file

### Debug Steps

```bash
# 1. Check component status
./cli/nova status <component> <env>

# 2. View logs
./cli/nova logs <component> <env>

# 3. Check events
kubectl get events -n nova-dev<component> --sort-by='.lastTimestamp'

# 4. Describe resources
kubectl describe deployment <component> -n nova-dev<component>
```

## Issue: Remote chart deployment fails

### Problem
Helm repository not added or chart name incorrect.

### Solution

1. **Add repositories:**
   ```bash
   ./cli/nova pull-charts
   ```

2. **Verify repository:**
   ```bash
   helm repo list
   helm repo update
   ```

3. **Search for chart:**
   ```bash
   helm search repo <chart-name>
   ```

## Quick Fixes

### Reset Everything
```bash
# Remove all Helm releases
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | grep "^nova-"); do
    helm list -n "$ns" -q | xargs -r helm uninstall -n "$ns"
done
```

### Clean Up Failed Deployments
```bash
# Delete stuck pods
kubectl delete pod --field-selector=status.phase!=Running --all-namespaces

# Restart deployment
kubectl rollout restart deployment/<component> -n nova-dev<component>
```

### Re-add Helm Repositories
```bash
./cli/nova pull-charts
```

## Getting Help

1. **Check CLI help:**
   ```bash
   ./cli/nova help
   ```

2. **List components:**
   ```bash
   ./cli/nova list
   ```

3. **Run troubleshooting script:**
   ```bash
   ./scripts/13-troubleshoot.sh
   ```

4. **Check health:**
   ```bash
   ./cli/nova health
   ```

## Common Commands

```bash
# Add Helm repos (do this first!)
./cli/nova pull-charts

# Deploy component
./cli/nova deploy <component> dev

# Check status
./cli/nova status <component> dev

# View logs
./cli/nova logs <component> dev

# Rollback if needed
./cli/nova rollback <component> dev
```
