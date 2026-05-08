# Local Helm Repositories

This directory contains local Helm repositories for all platform tools and applications.

## Structure

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
├── application/       # Application component charts
│   ├── chatmcp-app/
│   ├── discomine-app/
│   ├── milvus/
│   ├── minio-operator/
│   ├── miniolab/
│   ├── novaridium-app/
│   ├── vectorization-service/
│   ├── novaridium-flyte/
│   ├── novaridium-ollama/
│   ├── novaridium-openfga/
│   ├── novaridium-pgadmin/
│   ├── novaridium-postgres/
│   ├── validator-app/
│   ├── langfuse/
│   ├── neo4j/
│   ├── prefect/
│   ├── kubelens/
│   └── redis/
└── index.yaml         # Repository index (auto-generated)
```

## Usage

### Add Local Repository
```bash
helm repo add platform-repo file://$(pwd)/helm-repos/platform
helm repo add app-repo file://$(pwd)/helm-repos/application
helm repo update
```

### Install from Repository
```bash
helm install cilium platform-repo/cilium --namespace nova-devcilium
helm install novaridium-app app-repo/novaridium-app --namespace nova-prodnovaridium-app
```

## Naming Convention

### Namespaces
Format: `nova-<env><application-name>`

Examples:
- `nova-devcilium` - Development Cilium
- `nova-stagingnovaridium-app` - Staging Novaridium App
- `nova-prodpostgres` - Production PostgreSQL

### Domains
Format: `*.nova-<env-name>.eu.novartis.net`

Examples:
- `*.nova-dev.eu.novartis.net` - Development environment
- `*.nova-staging.eu.novartis.net` - Staging environment
- `*.nova-prod.eu.novartis.net` - Production environment

## Repository Management

### Adding Charts
1. Copy or create chart in appropriate directory
2. Package the chart: `helm package <chart-dir> -d <repo-dir>`
3. Update index: `helm repo index <repo-dir>`

### Updating Index
```bash
helm repo index helm-repos/platform --url file://helm-repos/platform
helm repo index helm-repos/application --url file://helm-repos/application
```

## CI/CD Integration

The CI/CD pipeline automatically:
- Packages charts during build
- Updates repository indexes
- Uses local repositories for deployments
