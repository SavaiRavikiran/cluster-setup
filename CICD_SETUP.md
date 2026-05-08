# Complete CI/CD Setup Guide

This document provides a complete guide for setting up the CI/CD infrastructure as specified.

## 1. CI/CD Setup

### a. Central Repository for Core Job Files/Templates

All core job templates are stored in `gitlab/ci-cd/`:

```
gitlab/ci-cd/
├── core/
│   └── .gitlab-ci.yml          # Central core job templates
├── templates/
│   ├── image-build.yml          # Image build with scanning
│   ├── helm-package.yml        # Helm package
│   ├── helm-deploy.yml         # Helm deploy
│   ├── helm-template.yml       # Helm template for in-house tools
│   ├── deployment.yml          # Base deployment template
│   └── ...
└── templates/repo-templates/
    ├── platform-tool-deployment.yml    # Platform tool template
    ├── application-deployment.yml      # Application template
    └── helm-packager.yml                # Helm packager template
```

### b. Helm Repositories

Local Helm repositories are organized as:

```
helm-repos/
├── platform/          # Platform component charts
│   ├── cilium/
│   ├── metallb/
│   ├── metrics-server/
│   ├── nfs-provisioner/
│   ├── kong/
│   ├── gitlab/
│   ├── gitlab-runner/
│   ├── prometheus/
│   ├── grafana/
│   ├── alertmanager/
│   └── wiz/
└── application/      # Application component charts
    ├── chatmcp-app/
    ├── discomine-app/
    ├── milvus/
    ├── minio-operator/
    ├── miniolab/
    ├── novaridium-app/
    ├── vectorization-service/
    ├── novaridium-flyte/
    ├── novaridium-ollama/
    ├── novaridium-openfga/
    ├── novaridium-pgadmin/
    ├── novaridium-postgres/
    ├── validator-app/
    ├── langfuse/
    ├── neo4j/
    ├── prefect/
    ├── kubelens/
    └── redis/
```

### c. Image Storage

All public images are stored in GitLab Container Registry:
- Location: `${CI_REGISTRY}/${CI_PROJECT_PATH}/images/`
- Script: `scripts/08-pull-and-store-images.sh`

## 2. Automation

### a. Initialize Release Version

```bash
./scripts/10-initialize-release-version.sh
```

This script:
- Increments version (major/minor/patch)
- Creates version file
- Updates release notes
- Creates Git tag

### b. Repository Templates

Templates are available for different repository types:

#### Platform Tool Deployment
```yaml
include:
  - local: 'gitlab/ci-cd/templates/repo-templates/platform-tool-deployment.yml'
```

#### Application Deployment
```yaml
include:
  - local: 'gitlab/ci-cd/templates/repo-templates/application-deployment.yml'
```

#### Helm Packager
```yaml
include:
  - local: 'gitlab/ci-cd/templates/repo-templates/helm-packager.yml'
```

### c. Image Pull and Store

```bash
./scripts/08-pull-and-store-images.sh
```

Pulls public images and stores them in GitLab registry.

### d. Helm Pull and Store

```bash
./scripts/09-pull-and-store-helm.sh
```

Pulls Helm charts from public repos and stores them locally.

### e. Cleanup Activity

```bash
./scripts/11-cleanup.sh
```

Cleans up:
- Old container images
- Old Helm charts
- Old Kubernetes resources
- Old log files

## 3. Naming Convention

### Namespaces
Format: `nova-<env><application-name>`

Examples:
- `nova-devcilium`
- `nova-stagingnovaridium-app`
- `nova-prodpostgres`

### Domains
Format: `*.nova-<env-name>.eu.novartis.net`

Examples:
- `*.nova-dev.eu.novartis.net`
- `*.nova-staging.eu.novartis.net`
- `*.nova-prod.eu.novartis.net`

See `config/naming-convention.md` for complete details.

## 4. Platform Components

All platform components are configured:

1. **cilium** - CNI network plugin
2. **metallb** - Load balancer
3. **metrics-server** - Kubernetes metrics
4. **nfs-provisioner** - Storage provisioner
5. **Kong** - API Gateway
6. **gitlab** - CI/CD platform
7. **gitlab-runner** - CI/CD executor
8. **prometheus** - Metrics collection
9. **grafana** - Visualization
10. **alertmanager** - Alert management
11. **wiz** - Security scanning

## 5. Application Components

All application components are configured:

1. **chatmcp-app** - Chat MCP application
2. **discomine-app** - Discomine application
3. **milvus** - Vector database
4. **minio-operator** - MinIO operator
5. **miniolab** - MinIO lab
6. **novaridium-app** - Main Novaridium application
7. **vectorization-service** - Vectorization service
8. **novaridium-flyte** - Flyte workflow
9. **novaridium-ollama** - Ollama LLM
10. **novaridium-openfga** - OpenFGA authorization
11. **novaridium-pgadmin** - PgAdmin database management
12. **novaridium-postgres** - PostgreSQL database
13. **validator-app** - Validator application
14. **langfuse** - LLM observability
15. **neo4j** - Graph database
16. **prefect** - Workflow orchestration
17. **kubelens** - Kubernetes visualization
18. **redis** - Cache/queue

## Usage Examples

### Creating a New Platform Tool Repository

1. Create new GitLab repository
2. Add `.gitlab-ci.yml`:
```yaml
include:
  - local: 'gitlab/ci-cd/templates/repo-templates/platform-tool-deployment.yml'
```
3. Add Helm chart structure
4. Push to repository

### Creating a New Application Repository

1. Create new GitLab repository
2. Add `.gitlab-ci.yml`:
```yaml
include:
  - local: 'gitlab/ci-cd/templates/repo-templates/application-deployment.yml'
```
3. Add application code and Helm chart
4. Push to repository

### Deploying a Component

1. Update values file for environment
2. Push to appropriate branch:
   - `develop` → dev environment
   - `main` → staging environment
   - `tags` → production environment
3. Manually trigger deployment job in GitLab UI

## Next Steps

1. **Configure GitLab Variables**: Set up Kubernetes credentials
2. **Pull Images**: Run `./scripts/08-pull-and-store-images.sh`
3. **Pull Charts**: Run `./scripts/09-pull-and-store-helm.sh`
4. **Initialize Version**: Run `./scripts/10-initialize-release-version.sh`
5. **Deploy**: Start with platform components, then applications

All components are ready for deployment with the new CI/CD infrastructure!
