#!/bin/bash
# Setup Jellyfin Tailscale Funnel exposure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy systemd service to /etc/systemd/system
sudo cp "$SCRIPT_DIR/jellyfin-funnel.service" /etc/systemd/system/

# Reload systemd and enable/start the service
sudo systemctl daemon-reload
sudo systemctl enable jellyfin-funnel.service
sudo systemctl restart jellyfin-funnel.service

# Wait for port forward to be ready
echo "Waiting for port-forward to be ready..."
sleep 3
for i in {1..10}; do
  if nc -z 127.0.0.1 8096 2>/dev/null; then
    echo "✓ Jellyfin accessible at 127.0.0.1:8096"
    break
  fi
  echo "  Attempt $i/10..."
  sleep 1
done

# Enable and start Tailscale Funnel
echo "Configuring Tailscale Funnel..."
tailscale funnel --bg 127.0.0.1:8096

# Get Tailscale IP for reference
TAILSCALE_IP=$(tailscale ip -4)
echo ""
echo "✓ Setup complete!"
echo ""
echo "Jellyfin is now exposed via Tailscale Funnel:"
echo "  - Service running: systemctl status jellyfin-funnel.service"
echo "  - Local access: http://127.0.0.1:8096"
echo "  - Tailscale access: http://$TAILSCALE_IP:8096"
echo "  - Funnel URL: Check 'tailscale funnel status'"
echo ""
echo "To stop/disable:"
echo "  sudo systemctl disable jellyfin-funnel.service"
echo "  sudo systemctl stop jellyfin-funnel.service"
echo "  tailscale funnel reset 127.0.0.1:8096"
