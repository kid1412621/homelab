# Jellyfin Tailscale Funnel Setup Guide

## Current Status
✓ Jellyfin K8s service is running  
✓ Port-forward to 127.0.0.1:8096 is active  
✓ Jellyfin is accessible locally  

## What's Needed
Tailscale Funnel requires sudo permissions. You have two options:

### Option 1: Set Tailscale Operator (Recommended - one-time setup)
```bash
# Set yourself as operator (one-time, requires sudo password once)
sudo tailscale set --operator=$USER

# Then enable Funnel without needing sudo
tailscale funnel --bg 127.0.0.1:8096
```

### Option 2: Run everything with sudo
```bash
# Enable Funnel directly (requires sudo each time)
sudo tailscale funnel --bg 127.0.0.1:8096
```

## Manual Setup Steps

### 1. Deploy Port-Forward Service (if not already running)
The system is already port-forwarding Jellyfin. To make it persistent across reboots:

```bash
# Copy systemd service
sudo cp /home/kid/homelab/jellyfin-funnel.service /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable jellyfin-funnel.service
sudo systemctl restart jellyfin-funnel.service

# Verify it's running
sudo systemctl status jellyfin-funnel.service
```

### 2. Enable Tailscale Funnel
```bash
# Option A: Set operator (one-time)
sudo tailscale set --operator=$USER
tailscale funnel --bg 127.0.0.1:8096

# Option B: Use sudo each time
sudo tailscale funnel --bg 127.0.0.1:8096
```

### 3. Verify Setup
```bash
# Check local access
curl http://127.0.0.1:8096/

# Check funnel status
tailscale funnel status

# Get public URL
tailscale status | grep -i funnel
```

## Access Methods
After setup, Jellyfin will be accessible via:

- **Local/SSH tunnel**: http://127.0.0.1:8096
- **Tailnet (private)**: http://100.97.153.46:8096 (your Tailscale IP)
- **Public (Funnel)**: URL shown in `tailscale funnel status`

## Management

### View logs
```bash
# Service logs
sudo journalctl -u jellyfin-funnel.service -f

# Funnel status
tailscale funnel status
```

### Stop/Disable
```bash
# Disable Funnel
sudo tailscale funnel reset 127.0.0.1:8096

# Stop port-forward service (if using systemd)
sudo systemctl stop jellyfin-funnel.service
sudo systemctl disable jellyfin-funnel.service
```

## Architecture

```
Jellyfin K8s Pod (8096)
       ↓
K8s ClusterIP Service (10.43.78.70:8096)
       ↓
kubectl port-forward (host)
       ↓
127.0.0.1:8096 (local)
       ↓
Tailscale Funnel
       ↓
Public funnel.tailscale.com URL
```

## Notes
- K8s manifests remain unchanged ✓
- Tailscale daemon runs on host ✓
- Minimal changes to system ✓
- Persistent across reboots (when systemd service is deployed) ✓
