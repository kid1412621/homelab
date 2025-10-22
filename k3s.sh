#!/bin/bash
set -eou pipefail

# check if installed
if (command -v "k3s" >/dev/null 2>&1); then
  exit 0
fi

# download and install k3s
curl -sfL https://get.k3s.io | sh -

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