#!/bin/bash
set -eou pipefail


if(command -v "k3s" >/dev/null 2>&1); then
  exit 0
fi

curl -sfL https://get.k3s.io | sh -

KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
