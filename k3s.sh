#!/bin/bash
set -eou pipefail

# check if installed
if (command -v "k3s" >/dev/null 2>&1); then
  exit 0
fi

# deploy k3s configuration with optimizations before installation
# this prevents Kine/SQLite bloat on long-running clusters
echo "Deploying K3s configuration with API server parameters..."
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml > /dev/null <<'EOF'
# K3s Production Configuration
# See: k3s-config.yaml for full documentation

kube-apiserver-arg:
  - "event-ttl=30m"
  - "max-requests-inflight=400"
  - "max-mutating-requests-inflight=200"
EOF
# download and install k3s
curl -sfL https://get.k3s.io | sh -

sudo tee /etc/systemd/system/k3s.service.env > /dev/null <<'EOF'
PATH=/var/lib/rancher/k3s/data/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF
sudo systemctl daemon-reload

# setup kubeconfig
KUBECONFIG=$HOME/.kube/config
mkdir $HOME/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

# write to shell rc file
RC_FILE="$HOME/$(shell_rc)"
if ! grep "$KUBECONFIG" "$RC_FILE"; then
  echo "export KUBECONFIG=\"$KUBECONFIG\"" >>"$RC_FILE"
fi

# configure firewall
sudo firewall-cmd --permanent --add-port=6443/tcp #apiserver
sudo firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 #pods
sudo firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 #services
sudo firewall-cmd --reload

echo "K3s installation complete with API server parameters applied."
