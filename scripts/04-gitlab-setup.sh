#!/bin/bash

# Script: 04-gitlab-setup.sh
# Description: Setup GitLab, GitLab CI/CD, and GitLab Runner
# Component: 2.10

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "GitLab Setup"
echo "=========================================="

# Create namespaces
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitlab-runner --dry-run=client -o yaml | kubectl apply -f -

# GitLab Configuration
if [ ! -f "$ROOT_DIR/gitlab/gitlab-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/gitlab"
    cat > "$ROOT_DIR/gitlab/gitlab-values.yaml" <<EOF
global:
  hosts:
    domain: # TODO: Set your domain (e.g., gitlab.example.com)
    gitlab:
      name: gitlab.example.com
  ingress:
    configureCertmanager: false
    class: nginx
  timeZone: UTC

certmanager:
  install: false

gitlab:
  gitlab-exporter:
    enabled: true
  webservice:
    replicas: 2
    minReplicas: 2
    maxReplicas: 4
    resources:
      requests:
        memory: "2Gi"
        cpu: "500m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
  sidekiq:
    replicas: 2
    resources:
      requests:
        memory: "1Gi"
        cpu: "200m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
  gitaly:
    persistence:
      enabled: true
      size: 50Gi
      storageClass: nfs-client
  postgresql:
    install: true
    persistence:
      enabled: true
      size: 20Gi
      storageClass: nfs-client
  redis:
    install: true
    persistence:
      enabled: true
      size: 5Gi
      storageClass: nfs-client
  minio:
    install: true
    persistence:
      enabled: true
      size: 50Gi
      storageClass: nfs-client

nginx-ingress:
  enabled: true
  controller:
    service:
      type: LoadBalancer

postgresql:
  production:
    install: false

redis:
  install: false
EOF
fi

# Install GitLab
echo ""
echo "Installing GitLab..."
helm repo add gitlab https://charts.gitlab.io || true
helm repo update

echo "NOTE: Update domain in gitlab/gitlab-values.yaml before installation"
echo "Then run: helm upgrade --install gitlab gitlab/gitlab --namespace gitlab --values gitlab/gitlab-values.yaml --timeout 600s"

# GitLab Runner Configuration
if [ ! -f "$ROOT_DIR/gitlab/runner/gitlab-runner-values.yaml" ]; then
    mkdir -p "$ROOT_DIR/gitlab/runner"
    cat > "$ROOT_DIR/gitlab/runner/gitlab-runner-values.yaml" <<EOF
gitlabUrl: # TODO: Set GitLab URL (e.g., https://gitlab.example.com)
runnerRegistrationToken: "" # TODO: Get from GitLab Admin -> Runners

rbac:
  create: true

runners:
  config: |
    [[runners]]
      [runners.kubernetes]
        namespace = "gitlab-runner"
        image = "docker:latest"
        privileged = true
        service_account = "gitlab-runner"
        [runners.kubernetes.volumes]
          [[runners.kubernetes.volumes.host_path]]
            name = "docker-sock"
            mount_path = "/var/run/docker.sock"
            host_path = "/var/run/docker.sock"
      [runners.cache]
        [runners.cache.s3]
          # Configure if using S3-compatible storage
      [runners.docker]
        tls_verify = false
        image = "docker:latest"
        privileged = true
        disable_entrypoint_overwrite = false
        oom_kill_disable = false
        disable_cache = false
        volumes = ["/cache"]
        shm_size = 0

  tags: "kubernetes,docker"
  runUntagged: true
  locked: false
  env:
    DOCKER_HOST: tcp://localhost:2375

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "1Gi"
    cpu: "500m"
EOF
fi

# CI/CD Pipeline Templates
mkdir -p "$ROOT_DIR/gitlab/ci-cd/templates"

# Base CI/CD template
cat > "$ROOT_DIR/gitlab/ci-cd/templates/.gitlab-ci.yml" <<'CIEOF'
# GitLab CI/CD Base Template
# Include this in your project's .gitlab-ci.yml

stages:
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  KUBERNETES_NAMESPACE: ${CI_PROJECT_NAME}
  HELM_VERSION: "3.12.0"

# Build stage
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - branches
    - tags

# Test stage
test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - echo "Running tests..."
    # Add your test commands here
  only:
    - branches

# Deploy stage
deploy:
  stage: deploy
  image: alpine/helm:latest
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl
    - mv kubectl /usr/local/bin/
    - kubectl config set-cluster k8s --server=$KUBE_SERVER
    - kubectl config set-credentials k8s --token=$KUBE_TOKEN
    - kubectl config set-context k8s --cluster=k8s --user=k8s
    - kubectl config use-context k8s
  script:
    - kubectl create namespace $KUBERNETES_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    - helm upgrade --install $CI_PROJECT_NAME ./helm --namespace $KUBERNETES_NAMESPACE
  environment:
    name: production
  only:
    - main
    - master
  when: manual
CIEOF

# Kubernetes deployment template
cat > "$ROOT_DIR/gitlab/ci-cd/templates/kubernetes-deploy.yml" <<'K8SEOF'
# Kubernetes Deployment Template
# Use this for Kubernetes deployments in CI/CD

deploy-kubernetes:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl apply -f k8s/
    - kubectl rollout status deployment/${CI_PROJECT_NAME} -n ${KUBERNETES_NAMESPACE}
  environment:
    name: ${CI_ENVIRONMENT_NAME}
    url: https://${CI_PROJECT_NAME}.${CI_ENVIRONMENT_DOMAIN}
  only:
    - main
    - master
K8SEOF

# Helm deployment template
cat > "$ROOT_DIR/gitlab/ci-cd/templates/helm-deploy.yml" <<'HELMEOF'
# Helm Deployment Template
# Use this for Helm-based deployments in CI/CD

deploy-helm:
  stage: deploy
  image: alpine/helm:latest
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl && mv kubectl /usr/local/bin/
  script:
    - helm upgrade --install ${CI_PROJECT_NAME} ./helm --namespace ${KUBERNETES_NAMESPACE} --create-namespace
    - kubectl rollout status deployment/${CI_PROJECT_NAME} -n ${KUBERNETES_NAMESPACE}
  environment:
    name: ${CI_ENVIRONMENT_NAME}
  only:
    - main
    - master
HELMEOF

echo ""
echo "=========================================="
echo "GitLab Setup Configuration Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update gitlab/gitlab-values.yaml with your domain"
echo "2. Install GitLab: helm upgrade --install gitlab gitlab/gitlab --namespace gitlab --values gitlab/gitlab-values.yaml"
echo "3. Get GitLab root password: kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d"
echo "4. Get runner token from GitLab UI (Admin -> Runners)"
echo "5. Update gitlab/runner/gitlab-runner-values.yaml with URL and token"
echo "6. Install runner: helm upgrade --install gitlab-runner gitlab/gitlab-runner --namespace gitlab-runner --values gitlab/runner/gitlab-runner-values.yaml"
echo ""
echo "CI/CD templates are available in gitlab/ci-cd/templates/"
