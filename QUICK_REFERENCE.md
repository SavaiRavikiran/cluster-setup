# Quick Reference Guide

Quick commands and shortcuts for developers and DevOps.

## Nova CLI Commands

### Basic Operations

```bash
# Deploy a component
./cli/nova deploy <component> [env]

# Update a component
./cli/nova update <component> [env]

# Check status
./cli/nova status [component] [env]

# Rollback
./cli/nova rollback <component> [env]

# List all components
./cli/nova list

# Validate configuration
./cli/nova validate <component>

# View logs
./cli/nova logs <component> [env]

# Health check
./cli/nova health
```

### Examples

```bash
# Deploy PostgreSQL to dev
./cli/nova deploy postgresql dev

# Check status of all components in staging
./cli/nova status "" staging

# Rollback novaridium-app in production
./cli/nova rollback novaridium-app prod

# View logs
./cli/nova logs postgresql dev

# Check cluster health
./cli/nova health
```

## Interactive Deployment

```bash
# Launch interactive deployment wizard
./scripts/12-interactive-deploy.sh
```

## Component Quick Deploy

### Platform Components

```bash
# Network
./cli/nova deploy cilium dev
./cli/nova deploy metallb dev
./cli/nova deploy kong dev

# Monitoring
./cli/nova deploy prometheus dev
./cli/nova deploy grafana dev
./cli/nova deploy alertmanager dev
```

### Application Components

```bash
# Database
./cli/nova deploy postgresql dev
./cli/nova deploy redis dev
./cli/nova deploy neo4j dev

# Storage
./cli/nova deploy minio dev
./cli/nova deploy milvus dev

# Applications
./cli/nova deploy novaridium-app dev
./cli/nova deploy flyte dev
./cli/nova deploy ollama dev
```

## Environment Management

```bash
# Set environment
export NOVA_ENV=dev
export NOVA_ENV=staging
export NOVA_ENV=prod

# Switch environment
./cli/nova switch-env dev
```

## Namespace Naming

Format: `nova-<env><component>`

Examples:
- `nova-devpostgresql`
- `nova-stagingnovaridium-app`
- `nova-prodredis`

## Domain Naming

Format: `<component>.nova-<env>.eu.novartis.net`

Examples:
- `postgresql.nova-dev.eu.novartis.net`
- `grafana.nova-staging.eu.novartis.net`
- `novaridium-app.nova-prod.eu.novartis.net`

## Common kubectl Commands

```bash
# Get all resources in namespace
kubectl get all -n nova-devpostgresql

# Describe deployment
kubectl describe deployment postgresql -n nova-devpostgresql

# Get pods
kubectl get pods -n nova-devpostgresql

# Get logs
kubectl logs -n nova-devpostgresql -l app=postgresql

# Port forward
kubectl port-forward -n nova-devpostgresql svc/postgresql 5432:5432

# Exec into pod
kubectl exec -it -n nova-devpostgresql deployment/postgresql -- bash
```

## Helm Commands

```bash
# List releases
helm list -n nova-devpostgresql

# Get values
helm get values postgresql -n nova-devpostgresql

# Upgrade
helm upgrade postgresql helm-repos/application/postgresql \
  -n nova-devpostgresql \
  -f novaridium/postgresql/postgresql-values.yaml

# Rollback
helm rollback postgresql -n nova-devpostgresql

# History
helm history postgresql -n nova-devpostgresql
```

## Troubleshooting

### Component Not Deploying

```bash
# Check namespace
kubectl get namespace nova-dev<component>

# Check events
kubectl get events -n nova-dev<component> --sort-by='.lastTimestamp'

# Check pod status
kubectl get pods -n nova-dev<component>

# Check logs
kubectl logs -n nova-dev<component> <pod-name>
```

### Rollback Issues

```bash
# Check Helm history
helm history <component> -n nova-dev<component>

# Manual rollback
helm rollback <component> <revision> -n nova-dev<component>
```

### Configuration Issues

```bash
# Validate values file
./cli/nova validate <component>

# Template chart
helm template <component> helm-repos/<category>/<component> \
  -f <values-file> --debug
```

## Quick Scripts

```bash
# Pull and store images
./scripts/08-pull-and-store-images.sh

# Pull and store Helm charts
./scripts/09-pull-and-store-helm.sh

# Package Helm charts
./scripts/07-package-helm-charts.sh

# Initialize release version
./scripts/10-initialize-release-version.sh

# Cleanup
./scripts/11-cleanup.sh

# Health check
./gitlab/ci-cd/scripts/health-check.sh
```

## CI/CD Quick Actions

### Deploy via GitLab

1. Push to branch:
   - `develop` → dev environment
   - `main` → staging environment
   - `tags` → production environment

2. Go to GitLab: CI/CD > Pipelines

3. Click "Play" on deployment job

### Manual Trigger

```bash
# Trigger pipeline via API
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --form "ref=develop" \
  "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/pipeline"
```

## Component Locations

### Values Files
- Platform: `cluster/<component>/<component>-values.yaml`
- Monitoring: `monitoring/<component>/<component>-values.yaml`
- Applications: `novaridium/<component>/<component>-values.yaml`

### Helm Charts
- Platform: `helm-repos/platform/<component>/`
- Applications: `helm-repos/application/<component>/`

## Environment Variables

```bash
# Set in your shell
export NOVA_ENV=dev
export NOVA_NAMESPACE_PREFIX=nova
export KUBECONFIG=~/.kube/config
```

## Getting Help

```bash
# CLI help
./cli/nova help

# Component list
./cli/nova list

# Check status
./cli/nova status
```

## Common Workflows

### Deploy New Component

```bash
1. ./cli/nova validate <component>
2. ./cli/nova deploy <component> dev
3. ./cli/nova status <component> dev
4. ./cli/nova logs <component> dev
```

### Update Component

```bash
1. Edit values file
2. ./cli/nova validate <component>
3. ./cli/nova update <component> dev
4. ./cli/nova status <component> dev
```

### Rollback Component

```bash
1. ./cli/nova status <component> <env>
2. ./cli/nova rollback <component> <env>
3. ./cli/nova status <component> <env>
```
