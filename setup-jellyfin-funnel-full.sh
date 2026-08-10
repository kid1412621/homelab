#!/bin/bash
# Deploy Jellyfin to Tailscale Funnel

set -e

echo "==== Jellyfin Tailscale Funnel Setup ===="
echo ""
echo "This script will:"
echo "  1. Deploy a port-forward systemd service"
echo "  2. Configure Tailscale Funnel to expose Jellyfin"
echo ""

REPO_DIR="/home/kid/homelab"
SERVICE_FILE="/etc/systemd/system/jellyfin-funnel.service"

# Step 1: Deploy systemd service
echo "[1/3] Deploying systemd service..."
if [ ! -f "$SERVICE_FILE" ]; then
  cp "$REPO_DIR/jellyfin-funnel.service" "$SERVICE_FILE"
  systemctl daemon-reload
  systemctl enable jellyfin-funnel.service
  systemctl restart jellyfin-funnel.service
  echo "✓ Service deployed and started"
else
  echo "✓ Service already exists"
fi

# Step 2: Verify port-forward
echo "[2/3] Verifying Jellyfin port-forward..."
sleep 2
for i in {1..10}; do
  if curl -s -m 1 http://127.0.0.1:8096/ > /dev/null 2>&1; then
    echo "✓ Jellyfin accessible at 127.0.0.1:8096"
    break
  fi
  sleep 1
done

# Step 3: Configure Tailscale Funnel
echo "[3/3] Configuring Tailscale Funnel..."
echo "This requires you to be in the Tailnet as admin or have operator permissions."
echo ""

# Try to get operator permission if needed
if ! sudo -n true 2>/dev/null; then
  echo "Attempting to set Tailscale operator permissions..."
  sudo tailscale set --operator=$USER
fi

# Enable Funnel
sudo tailscale funnel --bg 127.0.0.1:8096

echo ""
echo "==== Setup Complete ===="
echo ""
echo "Jellyfin is now exposed via Tailscale Funnel!"
echo ""
echo "Access methods:"
TAILSCALE_IP=$(tailscale ip -4)
echo "  • Local:           http://127.0.0.1:8096"
echo "  • Tailnet (LAN):   http://$TAILSCALE_IP:8096"
echo "  • Public (Funnel): Check 'tailscale funnel status'"
echo ""
echo "Management commands:"
echo "  • View funnel status:  tailscale funnel status"
echo "  • Service status:      sudo systemctl status jellyfin-funnel.service"
echo "  • Service logs:        sudo journalctl -u jellyfin-funnel.service -f"
echo "  • Disable funnel:      sudo tailscale funnel reset 127.0.0.1:8096"
echo "  • Disable service:     sudo systemctl disable jellyfin-funnel.service"
echo ""
