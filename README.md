# self-host

Kustomize configuration for a self-hosted k3s cluster.

Application services are exposed through Traefik Gateway API resources. The
shared `base/httproute.yml` attaches the normal app route to
`traefik/main-gateway`, and `../base` provides shared LAN/WAN domain values for
Kustomize replacements. Apps add their own `httproute.yml` only for extra routes.
