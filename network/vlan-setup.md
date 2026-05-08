# VLAN Creation and Network Setup

## Component: 1 - VLAN Creation

This document outlines the VLAN creation and network segmentation requirements for the Kubernetes cluster infrastructure.

## Network Architecture

### VLAN Requirements

The infrastructure requires the following VLANs for proper network segmentation:

1. **Management VLAN** (VLAN 10)
   - Purpose: Cluster management, SSH access, monitoring
   - IP Range: 192.168.10.0/24
   - Access: Restricted to admin networks

2. **Kubernetes Control Plane VLAN** (VLAN 20)
   - Purpose: Kubernetes API server, etcd, control plane components
   - IP Range: 192.168.20.0/24
   - Access: Restricted to master nodes and authorized services

3. **Kubernetes Pod Network VLAN** (VLAN 30)
   - Purpose: Pod-to-pod communication (Cilium CNI)
   - IP Range: 10.0.0.0/16 (configurable)
   - Access: Internal cluster communication only

4. **Services VLAN** (VLAN 40)
   - Purpose: LoadBalancer services, Ingress controllers
   - IP Range: 192.168.40.0/24
   - Access: External access to services

5. **Storage VLAN** (VLAN 50)
   - Purpose: NFS, storage backend communication
   - IP Range: 192.168.50.0/24
   - Access: Restricted to storage and compute nodes

6. **External/Internet VLAN** (VLAN 100)
   - Purpose: Internet access, external API calls
   - IP Range: 192.168.100.0/24
   - Access: Outbound internet access with proxy support

## VLAN Configuration Steps

### On Network Switch/Router

1. **Create VLANs**
   ```bash
   # Example for Cisco switch
   configure terminal
   vlan 10
     name Management
   vlan 20
     name K8s-ControlPlane
   vlan 30
     name K8s-PodNetwork
   vlan 40
     name Services
   vlan 50
     name Storage
   vlan 100
     name External
   exit
   ```

2. **Assign Ports to VLANs**
   - Management ports: VLAN 10
   - Master node ports: VLAN 10, 20
   - Worker node ports: VLAN 10, 30, 40
   - Storage node ports: VLAN 10, 50

3. **Configure Trunk Ports**
   - Ports connecting to Kubernetes nodes should be trunk ports
   - Allow all required VLANs on trunk ports

### On Kubernetes Nodes

1. **Configure Network Interfaces**
   ```bash
   # Example network configuration
   # /etc/netplan/01-netcfg.yaml
   network:
     version: 2
     renderer: networkd
     ethernets:
       eth0:
         addresses:
           - 192.168.10.10/24  # Management VLAN
         gateway4: 192.168.10.1
         nameservers:
           addresses:
             - 8.8.8.8
             - 8.8.4.4
   ```

2. **VLAN Tagging (if required)**
   ```bash
   # Install vlan package
   apt-get install vlan
   
   # Load 8021q module
   modprobe 8021q
   echo "8021q" >> /etc/modules
   
   # Configure VLAN interface
   vconfig add eth0 20  # For VLAN 20
   ifconfig eth0.20 192.168.20.10 netmask 255.255.255.0
   ```

## Network Requirements

### Proxy Configuration

The following URLs must be accessible through proxy:

- `https://pypi.python.org`
- `registry.ollama.com/`
- `*.ollama.com/`
- `https://www.python.org/downloads/`

### Proxy Setup on Nodes

```bash
# /etc/environment
http_proxy="http://proxy.example.com:8080"
https_proxy="http://proxy.example.com:8080"
no_proxy="localhost,127.0.0.1,.svc,.svc.cluster.local,10.0.0.0/8,192.168.0.0/16"

# Docker proxy
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,.svc,.svc.cluster.local"
EOF

# Kubernetes proxy
cat > /etc/kubernetes/proxy.env <<EOF
HTTP_PROXY=http://proxy.example.com:8080
HTTPS_PROXY=http://proxy.example.com:8080
NO_PROXY=localhost,127.0.0.1,.svc,.svc.cluster.local,10.0.0.0/8
EOF
```

## Firewall Rules

### Required Ports

**Master Nodes:**
- 6443: Kubernetes API server
- 2379-2380: etcd server client API
- 10250: Kubelet API
- 10259: kube-scheduler
- 10257: kube-controller-manager

**Worker Nodes:**
- 10250: Kubelet API
- 30000-32767: NodePort Services

**All Nodes:**
- 22: SSH
- 80, 443: HTTP/HTTPS (for Ingress)

## Network Verification

```bash
# Verify VLAN configuration
ip addr show

# Test connectivity
ping -c 3 192.168.10.1  # Gateway
ping -c 3 8.8.8.8        # Internet

# Test proxy
curl -I --proxy http://proxy.example.com:8080 https://pypi.python.org
```

## Next Steps

After VLAN setup is complete:
1. Verify network connectivity
2. Configure proxy settings on all nodes
3. Proceed with cluster setup (Component 2.0 - Prerequisites Check)
