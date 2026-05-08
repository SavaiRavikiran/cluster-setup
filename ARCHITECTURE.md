# Complete Infrastructure Architecture

This document describes the complete architecture of the Kubernetes cluster infrastructure with all components, their relationships, and deployment strategy.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Network Layer                                 │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  • Cilium CNI (Network Plugin)                                  │   │
│  │  • Envoy Proxy (Service Mesh)                                   │   │
│  │  • Nginx Ingress Controller (Ingress)                          │   │
│  │  • MetalLB (Load Balancer)                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Storage Layer                                 │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  • NFS Subdir External Provisioner                              │   │
│  │  • Storage Classes: nfs-client                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Core Infrastructure                                  │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  • Hashicorp Vault (Secrets Management)                         │   │
│  │  • PKI Setup (Certificate Authority)                            │   │
│  │  • Helm (Package Manager)                                        │   │
│  │  • GitLab (CI/CD Platform)                                      │   │
│  │  • GitLab Runner (CI/CD Execution)                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                  Monitoring Stack                               │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  • Prometheus (Metrics Collection)                               │   │
│  │  • AlertManager (Alert Management)                              │   │
│  │  • Grafana (Visualization)                                      │   │
│  │  • Loki (Log Aggregation)                                       │   │
│  │  • Metrics Server (K8s Metrics)                                 │   │
│  │  • Exporters (Blackbox, Node, Airbyte)                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Novaridium Application Stack                        │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │                                                                   │   │
│  │  ┌─────────────────── Data Layer ───────────────────┐            │   │
│  │  │  • PostgreSQL (Primary Database)                │            │   │
│  │  │  • MinIO (Object Storage)                        │            │   │
│  │  │  • Milvus (Vector Database)                       │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  │  ┌─────────────────── Processing Layer ─────────────┐            │   │
│  │  │  • Airbyte (Data Integration)                     │            │   │
│  │  │  • Flyte (Workflow Orchestration)                │            │   │
│  │  │  • Prefect (Workflow Management)                 │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  │  ┌─────────────────── AI/ML Layer ─────────────────┐            │   │
│  │  │  • Ollama (LLM Service)                          │            │   │
│  │  │  • Chat MCP (Vectorization Service)              │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  │  ┌─────────────────── Security Layer ───────────────┐            │   │
│  │  │  • OpenFGA (Authorization)                      │            │   │
│  │  │  • OpenSPG (Knowledge Graph)                     │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  │  ┌─────────────────── Application Layer ──────────┐            │   │
│  │  │  • Novaridium (Main Application)                │            │   │
│  │  │  • Discomine                                     │            │   │
│  │  │  • Validator                                     │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  │  ┌─────────────────── Management Layer ───────────┐            │   │
│  │  │  • PgAdmin (Database Management)                 │            │   │
│  │  └──────────────────────────────────────────────────┘            │   │
│  │                                                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Network Layer

#### Cilium CNI
- **Purpose**: Container network interface plugin
- **Features**: 
  - eBPF-based networking
  - Network policies
  - Service mesh capabilities
  - Hubble observability
- **Namespace**: `cilium-system`
- **Dependencies**: None (core component)

#### Envoy Proxy
- **Purpose**: Service mesh and API gateway
- **Features**: 
  - Traffic management
  - Load balancing
  - Circuit breaking
- **Namespace**: `envoy-system`
- **Dependencies**: Cilium

#### Nginx Ingress Controller
- **Purpose**: HTTP/HTTPS ingress controller
- **Features**: 
  - SSL termination
  - Load balancing
  - Path-based routing
- **Namespace**: `ingress-nginx`
- **Dependencies**: MetalLB (for LoadBalancer services)

#### MetalLB
- **Purpose**: Load balancer for bare metal Kubernetes
- **Features**: 
  - Layer 2 and BGP modes
  - IP address management
- **Namespace**: `metallb-system`
- **Dependencies**: None

### Storage Layer

#### NFS Subdir External Provisioner
- **Purpose**: Dynamic volume provisioning using NFS
- **Features**: 
  - Automatic volume creation
  - Storage class management
- **Namespace**: `nfs-system`
- **Dependencies**: NFS server

### Core Infrastructure

#### Hashicorp Vault
- **Purpose**: Secrets management
- **Features**: 
  - Secret storage and encryption
  - Dynamic secrets
  - PKI management
- **Namespace**: `vault`
- **Dependencies**: Storage (NFS)

#### GitLab
- **Purpose**: CI/CD platform and Git repository
- **Features**: 
  - Source code management
  - CI/CD pipelines
  - Container registry
- **Namespace**: `gitlab`
- **Dependencies**: PostgreSQL, Redis, MinIO, Storage

#### GitLab Runner
- **Purpose**: Execute CI/CD jobs
- **Features**: 
  - Kubernetes executor
  - Docker executor
- **Namespace**: `gitlab-runner`
- **Dependencies**: GitLab

### Monitoring Stack

#### Prometheus
- **Purpose**: Metrics collection and alerting
- **Features**: 
  - Time-series database
  - PromQL query language
  - Service discovery
- **Namespace**: `monitoring`
- **Dependencies**: Storage (NFS)

#### AlertManager
- **Purpose**: Alert routing and notification
- **Features**: 
  - Alert grouping
  - Inhibition rules
  - Multiple notification channels
- **Namespace**: `monitoring`
- **Dependencies**: Prometheus

#### Grafana
- **Purpose**: Metrics visualization and dashboards
- **Features**: 
  - Dashboard management
  - Alerting
  - Data source integration
- **Namespace**: `monitoring`
- **Dependencies**: Prometheus, Loki

#### Loki
- **Purpose**: Log aggregation
- **Features**: 
  - Log collection
  - LogQL query language
  - Label-based indexing
- **Namespace**: `monitoring`
- **Dependencies**: MinIO (for storage)

### Novaridium Application Stack

#### Data Layer

**PostgreSQL**
- **Purpose**: Primary relational database
- **Features**: 
  - ACID compliance
  - JSON support
  - Full-text search
- **Namespace**: `novaridium`
- **Dependencies**: Storage (NFS)

**MinIO**
- **Purpose**: S3-compatible object storage
- **Features**: 
  - Distributed mode
  - Bucket management
  - Access control
- **Namespace**: `novaridium`
- **Dependencies**: Storage (NFS)

**Milvus**
- **Purpose**: Vector database for AI/ML
- **Features**: 
  - Vector similarity search
  - Distributed architecture
  - High performance
- **Namespace**: `novaridium`
- **Dependencies**: MinIO, etcd, Pulsar

#### Processing Layer

**Airbyte**
- **Purpose**: Data integration platform
- **Features**: 
  - ETL pipelines
  - Connector library
  - Data synchronization
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL, Storage

**Flyte**
- **Purpose**: Workflow orchestration platform
- **Features**: 
  - Workflow definition
  - Task scheduling
  - SSO integration
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL, MinIO

**Prefect**
- **Purpose**: Workflow management
- **Features**: 
  - Workflow orchestration
  - Task scheduling
  - Monitoring
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL

#### AI/ML Layer

**Ollama**
- **Purpose**: Large Language Model service
- **Features**: 
  - Model hosting
  - API access
  - Model management
- **Namespace**: `novaridium`
- **Dependencies**: Storage (for models)

**Chat MCP**
- **Purpose**: Vectorization and chat service
- **Features**: 
  - Text vectorization
  - Chat interface
  - Integration with LLMs
- **Namespace**: `novaridium`
- **Dependencies**: Milvus, Ollama, OpenFGA

#### Security Layer

**OpenFGA**
- **Purpose**: Fine-grained authorization
- **Features**: 
  - Relationship-based access control
  - Policy engine
  - API access
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL

**OpenSPG**
- **Purpose**: Knowledge graph platform
- **Features**: 
  - Graph database
  - Knowledge representation
  - Query interface
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL, MinIO

#### Application Layer

**Novaridium**
- **Purpose**: Main application platform
- **Features**: 
  - Core business logic
  - API services
  - User interface
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL, Milvus, MinIO, Ollama, OpenFGA

**Discomine**
- **Purpose**: Application component
- **Features**: 
  - Business logic
  - Data processing
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL

**Validator**
- **Purpose**: Validation service
- **Features**: 
  - Data validation
  - Rule engine
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL

#### Management Layer

**PgAdmin**
- **Purpose**: PostgreSQL database management
- **Features**: 
  - Database administration
  - Query interface
  - User management
- **Namespace**: `novaridium`
- **Dependencies**: PostgreSQL

## Data Flow

### Application Request Flow
```
User Request
    ↓
Nginx Ingress Controller
    ↓
Application Service (Novaridium/Discomine/Validator)
    ↓
Database (PostgreSQL) / Vector DB (Milvus) / Object Storage (MinIO)
```

### CI/CD Flow
```
Git Push
    ↓
GitLab CI/CD Pipeline
    ↓
GitLab Runner
    ↓
Build & Test
    ↓
Deploy to Kubernetes
    ↓
Health Check & Verification
```

### Monitoring Flow
```
Application Metrics/Logs
    ↓
Prometheus (Metrics) / Loki (Logs)
    ↓
Grafana (Visualization)
    ↓
AlertManager (Alerts)
    ↓
Notification Channels (Slack/Email)
```

## Deployment Strategy

### Local Helm Charts
All Helm charts are stored locally in the `helm-charts/` directory to:
- Avoid dependency on external Helm repositories
- Ensure version control and reproducibility
- Enable offline deployments
- Support air-gapped environments

### CI/CD Pipeline
- **Validation**: YAML and Helm chart validation
- **Security**: Secret scanning and vulnerability checks
- **Deployment**: Multi-environment support (dev/staging/production)
- **Rollback**: Automatic rollback on failure
- **Monitoring**: Post-deployment health checks

### Environment Strategy
- **Development**: Fast iteration, minimal resources
- **Staging**: Production-like environment for testing
- **Production**: High availability, resource optimization

## Security Architecture

### Network Security
- Network policies for namespace isolation
- Service mesh for encrypted communication
- Ingress with TLS termination

### Secrets Management
- Vault for secret storage
- Kubernetes secrets for runtime
- Encrypted at rest and in transit

### Access Control
- RBAC for Kubernetes resources
- OpenFGA for application-level authorization
- Service accounts with least privilege

## High Availability

### Component Replication
- **Stateless services**: 2-3 replicas
- **Stateful services**: Primary + replicas
- **Databases**: Primary + read replicas

### Storage
- Persistent volumes with NFS
- Backup strategies for critical data
- Disaster recovery planning

### Monitoring
- Health checks and probes
- Automatic restart on failure
- Resource limits and requests

## Scalability

### Horizontal Scaling
- HPA (Horizontal Pod Autoscaler) for stateless services
- Cluster autoscaling for node management

### Vertical Scaling
- Resource requests and limits
- Node resource allocation

### Storage Scaling
- Dynamic volume provisioning
- Storage class expansion

## Backup and Recovery

### Database Backups
- PostgreSQL: Automated backups to MinIO
- Retention policies: 30 days

### Configuration Backups
- Git repository for all configurations
- Helm chart versioning
- Values file versioning

### Disaster Recovery
- Regular backup testing
- Recovery procedures documented
- RTO/RPO targets defined

## Network Architecture

### Internal Communication
- Service mesh (Envoy) for inter-service communication
- Service discovery via Kubernetes DNS
- Network policies for traffic control

### External Access
- Ingress controller for HTTP/HTTPS
- Load balancer (MetalLB) for services
- Firewall rules and security groups

## Resource Requirements

### Minimum Requirements
- **Control Plane**: 4 CPU, 8GB RAM
- **Worker Nodes**: 8 CPU, 16GB RAM (per node)
- **Storage**: 500GB (minimum)

### Recommended Requirements
- **Control Plane**: 8 CPU, 16GB RAM
- **Worker Nodes**: 16 CPU, 32GB RAM (per node)
- **Storage**: 2TB+

## Dependencies Graph

```
Cilium → Envoy
MetalLB → Nginx Ingress
NFS → All Persistent Storage
PostgreSQL → Most Applications
MinIO → Milvus, Loki, Airbyte, Flyte
Milvus → Chat MCP, Novaridium
Ollama → Chat MCP, Novaridium
OpenFGA → Chat MCP, Novaridium
Prometheus → Grafana, AlertManager
```

## Deployment Order

1. **Network Layer**: Cilium → MetalLB → Nginx Ingress
2. **Storage**: NFS Provisioner
3. **Core Infrastructure**: Vault → GitLab → GitLab Runner
4. **Monitoring**: Prometheus → AlertManager → Grafana → Loki
5. **Data Layer**: PostgreSQL → MinIO → Milvus
6. **Processing Layer**: Airbyte → Flyte → Prefect
7. **AI/ML Layer**: Ollama → Chat MCP
8. **Security Layer**: OpenFGA → OpenSPG
9. **Application Layer**: Novaridium → Discomine → Validator
10. **Management**: PgAdmin

This architecture provides a complete, production-ready infrastructure for the Novaridium platform with all necessary components, monitoring, and CI/CD capabilities.
