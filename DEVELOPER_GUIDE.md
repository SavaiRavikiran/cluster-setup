# Developer & DevOps Guide

Complete guide for developers and DevOps engineers to work with the Nova cluster infrastructure.

## Getting Started

### 1. Setup

```bash
# Clone repository
git clone <repository-url>
cd cluster-setup

# Make scripts executable
chmod +x scripts/*.sh cli/nova

# Add CLI to PATH (optional)
export PATH=$PATH:$(pwd)/cli
```

### 2. Prerequisites Check

```bash
# Check all prerequisites
./scripts/13-troubleshoot.sh
# Select option 1

# Or use CLI
./cli/nova health
```

## Daily Operations

### Deploying Components

#### Option 1: Using Nova CLI (Recommended)

```bash
# Deploy a component
./cli/nova deploy postgresql dev

# Deploy to specific environment
./cli/nova deploy novaridium-app staging

# Deploy to production
./cli/nova deploy novaridium-app prod
```

#### Option 2: Interactive Deployment

```bash
# Launch interactive wizard
./scripts/12-interactive-deploy.sh
```

#### Option 3: Manual Helm Deploy

```bash
# Deploy using Helm directly
helm upgrade --install postgresql \
  helm-repos/application/postgresql \
  -n nova-devpostgresql \
  -f novaridium/postgresql/postgresql-values.yaml
```

### Updating Components

```bash
# Update values file
vim novaridium/postgresql/postgresql-values.yaml

# Validate changes
./cli/nova validate postgresql

# Deploy update
./cli/nova update postgresql dev
```

### Checking Status

```bash
# Check all components
./cli/nova status

# Check specific component
./cli/nova status postgresql dev

# Check in all environments
./cli/nova status postgresql dev
./cli/nova status postgresql staging
./cli/nova status postgresql prod
```

### Viewing Logs

```bash
# View logs
./cli/nova logs postgresql dev

# Or use kubectl
kubectl logs -n nova-devpostgresql -l app=postgresql -f
```

### Rolling Back

```bash
# Rollback to previous version
./cli/nova rollback postgresql dev

# Or use Helm
helm rollback postgresql -n nova-devpostgresql
```

## Common Tasks

### Adding a New Component

1. **Create values file:**
   ```bash
   mkdir -p novaridium/my-component
   vim novaridium/my-component/my-component-values.yaml
   ```

2. **Add Helm chart:**
   ```bash
   # Copy chart to helm-repos
   cp -r <chart-dir> helm-repos/application/my-component
   ```

3. **Validate:**
   ```bash
   ./cli/nova validate my-component
   ```

4. **Deploy:**
   ```bash
   ./cli/nova deploy my-component dev
   ```

### Updating Configuration

1. **Edit values file:**
   ```bash
   vim novaridium/postgresql/postgresql-values.yaml
   ```

2. **Validate:**
   ```bash
   ./cli/nova validate postgresql
   ```

3. **Deploy:**
   ```bash
   ./cli/nova update postgresql dev
   ```

### Troubleshooting

```bash
# Run troubleshooting helper
./scripts/13-troubleshoot.sh

# Check component health
./cli/nova health

# View component status
./cli/nova status <component> <env>

# View logs
./cli/nova logs <component> <env>
```

## Environment Management

### Switching Environments

```bash
# Set environment variable
export NOVA_ENV=dev
export NOVA_ENV=staging
export NOVA_ENV=prod

# Or use CLI
./cli/nova switch-env dev
```

### Environment-Specific Values

Values files can be environment-specific:
- `values-dev.yaml` - Development
- `values-staging.yaml` - Staging
- `values-production.yaml` - Production

## CI/CD Workflow

### Development Workflow

1. **Create feature branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes:**
   ```bash
   vim novaridium/my-component/my-component-values.yaml
   ```

3. **Test locally:**
   ```bash
   ./cli/nova validate my-component
   ./cli/nova deploy my-component dev
   ```

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Update my-component configuration"
   git push origin feature/my-feature
   ```

5. **Create merge request:**
   - Go to GitLab
   - Create MR to `develop` branch
   - Pipeline will run automatically

### Staging Deployment

1. **Merge to main:**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. **Deploy to staging:**
   - Go to GitLab: CI/CD > Pipelines
   - Click "Play" on staging deployment job

### Production Deployment

1. **Create release tag:**
   ```bash
   ./scripts/10-initialize-release-version.sh
   # Or manually:
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **Deploy to production:**
   - Go to GitLab: CI/CD > Pipelines
   - Click "Play" on production deployment job

## Best Practices

### 1. Always Validate Before Deploy

```bash
./cli/nova validate <component>
```

### 2. Test in Dev First

```bash
# Deploy to dev
./cli/nova deploy <component> dev

# Verify
./cli/nova status <component> dev
./cli/nova logs <component> dev

# Then promote to staging/prod
```

### 3. Use Version Control

- Always commit values files
- Use meaningful commit messages
- Tag releases properly

### 4. Monitor Deployments

```bash
# Watch deployment status
watch -n 2 './cli/nova status <component> <env>'

# Or use kubectl
kubectl get pods -n nova-dev<component> -w
```

### 5. Keep Documentation Updated

- Update values files with comments
- Document any custom configurations
- Update this guide as needed

## Quick Reference

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for:
- Common commands
- Component locations
- Troubleshooting tips
- kubectl shortcuts

## Getting Help

1. **Check documentation:**
   - `README.md` - Overview
   - `QUICK_REFERENCE.md` - Quick commands
   - `ARCHITECTURE.md` - Architecture details
   - `CICD_SETUP.md` - CI/CD setup

2. **Use CLI help:**
   ```bash
   ./cli/nova help
   ```

3. **Run troubleshooting:**
   ```bash
   ./scripts/13-troubleshoot.sh
   ```

4. **Check component status:**
   ```bash
   ./cli/nova status
   ./cli/nova health
   ```

## Component Locations

### Values Files
- Platform: `cluster/<component>/<component>-values.yaml`
- Monitoring: `monitoring/<component>/<component>-values.yaml`
- Applications: `novaridium/<component>/<component>-values.yaml`

### Helm Charts
- Platform: `helm-repos/platform/<component>/`
- Applications: `helm-repos/application/<component>/`

## Naming Conventions

### Namespaces
Format: `nova-<env><component>`
- `nova-devpostgresql`
- `nova-stagingnovaridium-app`
- `nova-prodredis`

### Domains
Format: `<component>.nova-<env>.eu.novartis.net`
- `postgresql.nova-dev.eu.novartis.net`
- `grafana.nova-staging.eu.novartis.net`

See [config/naming-convention.md](config/naming-convention.md) for details.

## Automation Scripts

```bash
# Pull and store images
./scripts/08-pull-and-store-images.sh

# Pull and store Helm charts
./scripts/09-pull-and-store-helm.sh

# Package Helm charts
./scripts/07-package-helm-charts.sh

# Initialize release version
./scripts/10-initialize-release-version.sh

# Cleanup old resources
./scripts/11-cleanup.sh
```

## Tips & Tricks

1. **Use aliases:**
   ```bash
   alias nova='./cli/nova'
   alias deploy='./scripts/12-interactive-deploy.sh'
   alias troubleshoot='./scripts/13-troubleshoot.sh'
   ```

2. **Set default environment:**
   ```bash
   export NOVA_ENV=dev
   # Now you can use: ./cli/nova deploy postgresql
   ```

3. **Watch deployments:**
   ```bash
   watch -n 2 './cli/nova status postgresql dev'
   ```

4. **Quick port forward:**
   ```bash
   kubectl port-forward -n nova-devpostgresql svc/postgresql 5432:5432
   ```

5. **Quick shell access:**
   ```bash
   kubectl exec -it -n nova-devpostgresql deployment/postgresql -- bash
   ```

Happy deploying! 🚀
