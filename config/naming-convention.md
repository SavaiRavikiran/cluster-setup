# Naming Convention

This document defines the naming conventions used across the infrastructure.

## Namespaces

### Format
```
nova-<env><application-name>
```

### Examples
- `nova-devcilium` - Development Cilium
- `nova-devmetallb` - Development MetalLB
- `nova-devmetrics-server` - Development Metrics Server
- `nova-devkong` - Development Kong
- `nova-devgitlab` - Development GitLab
- `nova-devgitlab-runner` - Development GitLab Runner
- `nova-devprometheus` - Development Prometheus
- `nova-devgrafana` - Development Grafana
- `nova-devalertmanager` - Development AlertManager
- `nova-devwiz` - Development WIZ
- `nova-devchatmcp-app` - Development Chat MCP App
- `nova-devdiscomine-app` - Development Discomine App
- `nova-devmilvus` - Development Milvus
- `nova-devminio-operator` - Development MinIO Operator
- `nova-devminiolab` - Development MinIO Lab
- `nova-devnovaridium-app` - Development Novaridium App
- `nova-devvectorization-service` - Development Vectorization Service
- `nova-devnovaridium-flyte` - Development Novaridium Flyte
- `nova-devnovaridium-ollama` - Development Novaridium Ollama
- `nova-devnovaridium-openfga` - Development Novaridium OpenFGA
- `nova-devnovaridium-pgadmin` - Development Novaridium PgAdmin
- `nova-devnovaridium-postgres` - Development Novaridium PostgreSQL
- `nova-devvalidator-app` - Development Validator App
- `nova-devlangfuse` - Development Langfuse
- `nova-devneo4j` - Development Neo4j
- `nova-devprefect` - Development Prefect
- `nova-devkubelens` - Development Kubelens
- `nova-devredis` - Development Redis

### Staging Examples
- `nova-stagingnovaridium-app` - Staging Novaridium App
- `nova-stagingpostgres` - Staging PostgreSQL

### Production Examples
- `nova-prodnovaridium-app` - Production Novaridium App
- `nova-prodpostgres` - Production PostgreSQL

## Domains

### Format
```
*.nova-<env-name>.eu.novartis.net
```

### Examples
- `*.nova-dev.eu.novartis.net` - Development environment
- `*.nova-staging.eu.novartis.net` - Staging environment
- `*.nova-prod.eu.novartis.net` - Production environment

### Application-Specific Domains
- `novaridium-app.nova-dev.eu.novartis.net` - Development Novaridium App
- `grafana.nova-dev.eu.novartis.net` - Development Grafana
- `prometheus.nova-dev.eu.novartis.net` - Development Prometheus
- `kong-admin.nova-dev.eu.novartis.net` - Development Kong Admin
- `langfuse.nova-dev.eu.novartis.net` - Development Langfuse
- `neo4j.nova-dev.eu.novartis.net` - Development Neo4j
- `kubelens.nova-dev.eu.novartis.net` - Development Kubelens

## Helm Charts

### Platform Charts
- Location: `helm-repos/platform/`
- Naming: Component name (e.g., `cilium`, `metallb`, `kong`)

### Application Charts
- Location: `helm-repos/application/`
- Naming: Application name (e.g., `novaridium-app`, `chatmcp-app`)

## Container Images

### Format
```
${CI_REGISTRY}/${CI_PROJECT_PATH}/images/<component-name>:<tag>
```

### Examples
- `registry.gitlab.com/novaridium/cluster-setup/images/cilium:latest`
- `registry.gitlab.com/novaridium/cluster-setup/images/postgres:15`
- `registry.gitlab.com/novaridium/cluster-setup/images/novaridium-app:v1.0.0`

## GitLab CI/CD Variables

### Namespace Generation
```yaml
variables:
  ENV: "dev"  # or "staging" or "prod"
  APP_NAME: "novaridium-app"
  KUBERNETES_NAMESPACE: "nova-${ENV}${APP_NAME}"
```

### Domain Generation
```yaml
variables:
  ENV: "dev"
  APP_NAME: "novaridium-app"
  DOMAIN: "${APP_NAME}.nova-${ENV}.eu.novartis.net"
```

## Best Practices

1. **Consistency**: Always use the same naming pattern
2. **Lowercase**: All names should be lowercase
3. **Hyphens**: Use hyphens to separate words (not underscores)
4. **No Spaces**: Never use spaces in names
5. **Descriptive**: Names should clearly indicate what they represent
6. **Environment Prefix**: Always include environment in namespace names

## Migration Guide

If you have existing resources with different naming:
1. Update namespace names to follow new convention
2. Update domain names in ingress configurations
3. Update CI/CD variables
4. Update documentation
5. Test in dev environment first
