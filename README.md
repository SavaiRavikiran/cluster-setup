# Kubernetes Cluster Infrastructure Setup

This repository contains the complete infrastructure setup for a Kubernetes cluster with GitLab CI/CD, monitoring, and Novaridium components.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Setup Components](#setup-components)
4. [Quick Start](#quick-start)
5. [Component Details](#component-details)

## Prerequisites

### System Requirements
- Kubernetes cluster (v1.24+)
- kubectl configured
- Helm 3.x installed
- Ansible 2.9+ installed
- Access to nodes with sudo privileges
- Network access to required URLs (see [Network Requirements](#network-requirements))

### Network Requirements

The following URLs need to be accessible through proxy:
- `https://pypi.python.org`
- `registry.ollama.com/`
- `*.ollama.com/`
- `https://www.python.org/downloads/`

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
├─────────────────────────────────────────────────────────┤
│  Network Layer: Cilium CNI + Envoy Proxy                │
│  Ingress: Nginx Ingress Controller                      │
│  Load Balancer: MetalLB                                 │
│  Storage: NFS                                            │
├─────────────────────────────────────────────────────────┤
│  Core Infrastructure:                                    │
│  - Hashicorp Vault (Secrets Management)                 │
│  - PKI Setup                                             │
│  - Helm                                                   │
├─────────────────────────────────────────────────────────┤
│  CI/CD:                                                  │
│  - GitLab                                                │
│  - GitLab CI/CD                                          │
│  - GitLab Runner                                         │
├─────────────────────────────────────────────────────────┤
│  Monitoring Stack:                                       │
│  - Prometheus                                            │
│  - AlertManager                                          │
│  - Grafana                                               │
│  - Loki Stack (Vector/Loki)                              │
│  - Metrics Server                                        │
│  - Exporters (Blackbox, Node, Airbyte)                  │
├─────────────────────────────────────────────────────────┤
│  Novaridium Components:                                 │
│  - Airbyte                                               │
│  - Flyte (with SSO)                                      │
│  - Ollama (with PV for Models)                          │
│  - OpenFGA                                                │
│  - OpenSPG                                                │
│  - PgAdmin                                                │
│  - PostgreSQL                                             │
│  - Milvus                                                 │
│  - MinIO                                                  │
│  - Novaridium                                             │
│  - Discomine                                              │
│  - Validator App                                          │
│  - Chat MCP (Vectorization Service)                      │
└─────────────────────────────────────────────────────────┘
```

## Setup Components

### 1. VLAN Creation
- Network segmentation and isolation
- See `network/vlan-setup.md`

### 2. Cluster Setup
- **2.0**: Nodes Pre-requisite Check
- **2.1**: Kubernetes Network Setup - Cilium & Envoy
- **2.2**: Ingress Controller - Nginx
- **2.3**: Kubernetes Storage - NFS
- **2.4**: Helm
- **2.5**: Ansible
- **2.6**: Hashicorp Vault
- **2.7**: PKI Setup
- **2.8**: Ansible Scripting
- **2.9**: MetalLB Controller
- **2.10**: GitLab Setup

### 3. Monitoring Setup
- Prometheus
- AlertManager (with SNOW integration)
- Grafana
- Metrics Server
- Loki Stack
- Exporters

### 4. Novaridium Component Setup
- All application components listed above

## Quick Start

### 1. Clone and Prepare
```bash
cd cluster-setup
chmod +x scripts/*.sh
```

### 2. Run Prerequisites Check
```bash
./scripts/01-prerequisites-check.sh
```

### 3. Setup Network Layer
```bash
./scripts/02-network-setup.sh
```

### 4. Setup Core Infrastructure
```bash
./scripts/03-core-infra-setup.sh
```

### 5. Setup GitLab CI/CD
```bash
./scripts/04-gitlab-setup.sh
```

### 6. Setup Monitoring
```bash
./scripts/05-monitoring-setup.sh
```

### 7. Setup Novaridium Components
```bash
./scripts/06-novaridium-setup.sh
```

## Component Details

See individual component directories for detailed documentation:
- `cluster/` - Kubernetes cluster setup
- `gitlab/` - GitLab and CI/CD configuration
- `monitoring/` - Monitoring stack
- `novaridium/` - Application components
- `ansible/` - Ansible playbooks
- `vault/` - Vault configuration
- `pki/` - PKI setup

## CI/CD Pipeline

This repository includes a **production-ready CI/CD pipeline** for deploying all components:

### Quick Start
1. See [CI/CD Quick Start Guide](gitlab/ci-cd/QUICKSTART.md) for setup instructions
2. Configure GitLab CI/CD variables (see `gitlab/ci-cd/config/variables.example`)
3. Push code to trigger the pipeline

### Features
- ✅ Multi-environment support (dev, staging, production)
- ✅ Automated validation and security scanning
- ✅ Helm chart deployment for all components
- ✅ Rollback capabilities
- ✅ Health checks and verification
- ✅ Notification support (Slack, email)

### Documentation
- Full documentation: `gitlab/ci-cd/README.md`
- Quick start: `gitlab/ci-cd/QUICKSTART.md`
- Configuration examples: `gitlab/ci-cd/config/`

### Pipeline Stages
1. **Validate** - YAML and Helm chart validation
2. **Lint** - Code quality checks
3. **Security** - Secret and vulnerability scanning
4. **Deploy** - Environment-specific deployments
5. **Post-Deploy** - Verification and health checks
6. **Cleanup** - Resource cleanup

## Local Helm Charts

This repository uses **local Helm charts** instead of remote repositories:

- ✅ All charts stored in `helm-charts/` directory
- ✅ No dependency on external Helm repositories
- ✅ Works offline and in air-gapped environments
- ✅ Complete version control in Git

See [LOCAL_HELM_CHARTS.md](LOCAL_HELM_CHARTS.md) for details.

## Architecture

Complete infrastructure architecture documentation is available in [ARCHITECTURE.md](ARCHITECTURE.md), including:
- Component relationships and dependencies
- Data flow diagrams
- Deployment strategy
- Security architecture
- High availability design

## Developer Tools

### Nova CLI - Unified Command Interface

The Nova CLI makes it easy to deploy, update, and manage components:

```bash
# Deploy a component
./cli/nova deploy postgresql dev

# Check status
./cli/nova status

# Rollback
./cli/nova rollback postgresql dev

# View logs
./cli/nova logs postgresql dev

# Health check
./cli/nova health
```

### Interactive Deployment

```bash
# Launch interactive deployment wizard
./scripts/12-interactive-deploy.sh
```

### Troubleshooting Helper

```bash
# Diagnose and fix issues
./scripts/13-troubleshoot.sh
```

### Quick Reference

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for common commands and shortcuts.

### Developer Guide

See [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) for complete developer documentation.

## Notes

- All components are configured to work with proxy settings
- Ensure proper network connectivity before starting setup
- Review and customize values files in component directories before deployment
- Backup configurations before making changes
- All Helm charts are stored locally - no remote repository dependencies
- Use Nova CLI for easier component management# cluster-setup
