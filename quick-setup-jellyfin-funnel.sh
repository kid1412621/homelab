#!/bin/bash
# Quick setup: Run this to complete Jellyfin Funnel setup
# Usage: bash /home/kid/homelab/quick-setup-jellyfin-funnel.sh

echo "Setting up Jellyfin Tailscale Funnel..."
echo ""

# Step 1: Deploy systemd service
echo "[1/2] Deploying port-forward service..."
sudo cp /home/kid/homelab/jellyfin-funnel.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable jellyfin-funnel.service
sudo systemctl restart jellyfin-funnel.service
echo "✓ Port-forward service deployed"

# Step 2: Set Tailscale operator and enable Funnel
echo "[2/2] Configuring Tailscale Funnel..."
sudo tailscale set --operator=$USER
tailscale funnel --bg 127.0.0.1:8096
echo "✓ Tailscale Funnel enabled"

echo ""
echo "Setup complete! Jellyfin is now exposed via Tailscale Funnel."
echo ""
echo "Check status:"
echo "  tailscale funnel status"
echo ""
