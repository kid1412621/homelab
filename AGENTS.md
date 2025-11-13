# Project Overview

This repository contains the configuration for a self-hosted Kubernetes cluster, managed using Kustomize. The cluster is set up using k3s, a lightweight Kubernetes distribution. The repository follows the GitOps methodology, where the state of the cluster is defined by the YAML files in this repository.

The cluster runs various applications, including:

* **Media Management:** Jellyfin, Sonarr, Radarr, Bazarr, Prowlarr, qBittorrent
* **Home Automation:** Home Assistant
* **RSS Reader:** Miniflux
* **Continuous Deployment:** Keel
* **System Upgrade:** A system-upgrade controller

## Architecture

The repository is structured with a base configuration and overlays for each application.

* **`base/`:** Contains the base Kustomize configuration, including the Ingress controller setup and domain configuration
* **Application directories:** Each application has its own directory containing its Kubernetes manifests (Deployment, Service, PVC, etc.) and a `kustomization.yml` file
* **`kustomization.yml`:** The root Kustomization file defines all applications to be deployed
* **`traefik/`:** Traefik ingress controller configuration
* **`system-upgrade/`:** K3s automatic upgrade configuration

### Base Configuration
The `base/` directory contains shared resources used by all applications:
- `ingress.yml` - Template for ingress resources with dual-domain support (LAN and WAN)
- `kustomization.yml` - Base kustomization that generates domain config from `.env`
- `.env` - Domain configuration (LAN_DOMAIN and WAN_DOMAIN)

### Application Structure
Each application follows a consistent pattern:
- `namespace.yml` - Kubernetes namespace
- `deployment.yml` - Application deployment
- `service.yml` - Service definition
- `pvc.yml` - Persistent volume claim (if needed)
- `kustomization.yml` - Kustomize configuration
- `.env` or `.env.example` - Environment-specific configuration

### Domain Configuration
Applications are accessible via two domains:
- LAN: `{app-subdomain}.{lan-domain}` (e.g., `jellyfin.machine.lan`)
- WAN: `{app-subdomain}.{wan-domain}` (e.g., `jellyfin.domain.com`)

Each application's `kustomization.yml`:
1. Generates an `app-config` ConfigMap with the APP_SUBDOMAIN
2. Uses Kustomize replacements to inject subdomains into ingress rules
3. Injects the domain config from the base

### Traefik Ingress Controller
Traefik is deployed as the ingress controller:
- `traefik/helmchartconfig.yml` - HelmChartConfig for Traefik configuration
- `traefik/dashboard.yml` - Traefik dashboard ingress
- Supports both web (HTTP) and websecure (HTTPS) entrypoints

### Keel - Automated Updates
Keel provides automated container image updates:
- Watches for new image versions in configured registries
- Updates deployments automatically based on policies
- Provides web dashboard at keel subdomain
- Uses basic authentication (credentials in `keel/.env`)

### System Upgrade Controller
The `system-upgrade/` directory contains configuration for automatic K3s upgrades:
- Downloads latest system-upgrade-controller manifests from Rancher
- `plans.yml` defines upgrade strategies
- Currently configured for server-plan (control plane nodes)

# Building and Running

## Prerequisites

* A machine with a Linux distribution
* `curl` and `bash` installed
* `kubectl` installed and configured

## Installation

1. **Install k3s:**

    ```bash
    ./k3s.sh
    ```

2. **Configure domains:**
    - Copy `base/.env.example` to `base/.env`
    - Edit `base/.env` with your LAN_DOMAIN and WAN_DOMAIN
    - Copy app-specific `.env.example` files (e.g., `keel/.env.example`) to `.env` and configure

3. **Apply the Kubernetes manifests:**

    ```bash
    kubectl apply -k .
    ```

## Common Commands

### Deploy applications
```bash
# Apply all applications
kubectl apply -k .

# Apply a specific application
kubectl apply -k <app-name>/

# Preview changes before applying (dry run)
kubectl kustomize . | kubectl diff -f -

# View all resources
kubectl get all -A
```

### Manage K3s
```bash
# Install K3s (if not already installed)
./k3s.sh

# Check K3s status
systemctl status k3s

# View K3s logs
journalctl -u k3s -f
```

### System Upgrade
```bash
# Apply system upgrade controller
kubectl apply -k system-upgrade/

# Check upgrade plans
kubectl get plans -n system-upgrade

# View upgrade jobs
kubectl get jobs -n system-upgrade
```

### Application Management
```bash
# View application logs
kubectl logs -n <namespace> deployment/<app-name>

# Restart an application
kubectl rollout restart -n <namespace> deployment/<app-name>

# Check deployment status
kubectl get deployments -n <namespace>

# Check persistent volumes
kubectl get pvc -n <namespace>
```

## Application Inventory

| Application | Subdomain | Purpose |
|-------------|-----------|---------|
| traefik     | -         | Ingress controller |
| keel        | keel      | Automated updates |
| system-upgrade | -      | K3s auto-upgrade |
| jellyfin    | jellyfin  | Media server |
| sonarr      | sonarr    | TV show management |
| radarr      | radarr    | Movie management |
| bazarr      | bazarr    | Subtitles management |
| prowlarr    | prowlarr  | Indexer aggregator |
| qbittorrent | qb        | BitTorrent client |
| miniflux    | miniflux  | RSS feed reader |
| homeassistant | ha       | Home automation |

# Development Conventions

* All Kubernetes manifests are written in YAML
* The project uses Kustomize for managing Kubernetes configurations
* Each application has its own namespace
* Applications follow a consistent directory structure

## Environment Configuration

### Required Configuration Files
- `base/.env` - Must define LAN_DOMAIN and WAN_DOMAIN
- App-specific `.env` files (e.g., `keel/.env`, `miniflux/.env`) - See `.env.example` files

### Managing Secrets
- Use Kustomize `secretGenerator` to create secrets from `.env` files
- Secrets are referenced in deployments via `envFrom` or `valueFrom`
- Set `disableNameSuffixHash: true` for predictable secret names
- Consider using external secret management tools like HashiCorp Vault or Sealed Secrets for production

## Kustomize Features Used

* **Resource references**: Apps reference `../base` for shared configuration
* **ConfigMapGenerator**: Generates ConfigMaps from literals and files
* **SecretGenerator**: Generates Secrets from .env files
* **Replacements**: Injects subdomain and domain values into ingresses
* **Patches**: Customizes base ingress with app-specific service ports
* **Labels**: Consistent labeling across all resources
