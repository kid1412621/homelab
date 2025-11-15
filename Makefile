# Makefile for Homelab Kubernetes configurations

.PHONY: apply dry-run delete verify help

# Default target
help:
	@echo "Available commands:"
	@echo "  apply     - Apply all configurations to the cluster (kubectl apply -k .)"
	@echo "  dry-run   - Preview changes without applying (kubectl apply -k . --dry-run=client)"
	@echo "  delete    - Delete all configurations from the cluster (kubectl delete -k .)"
	@echo "  verify    - Verify all configurations can be built (kubectl kustomize .)"
	@echo ""
	@echo "Individual components:"
	@echo "  apply-traefik - Apply only Traefik configuration"
	@echo "  apply-keel    - Apply only Keel configuration"
	@echo "  apply-apps    - Apply all application configurations"

# Apply all configurations
apply:
	kubectl apply -k .

# Preview changes without applying
dry-run:
	kubectl apply -k . --dry-run=client

# Delete all configurations (use with caution!)
delete:
	kubectl delete -k .

# Verify all configurations can be built
verify:
	kubectl kustomize .

# Apply Traefik only
apply-traefik:
	kubectl apply -k traefik/

# Apply Keel only
apply-keel:
	kubectl apply -k keel/

# Apply all applications (excluding system components)
apply-apps:
	kubectl apply -k sonarr/ &
	kubectl apply -k radarr/ &
	kubectl apply -k bazarr/ &
	kubectl apply -k prowlarr/ &
	kubectl apply -k qbittorrent/ &
	kubectl apply -k jellyfin/ &
	kubectl apply -k homeassistant/ &
	kubectl apply -k miniflux/ &
	wait

# Apply system-upgrade
apply-system-upgrade:
	kubectl apply -k system-upgrade/

# Rollout restart all apps
restart-apps:
	kubectl rollout restart -n sonarr deployment/sonarr
	kubectl rollout restart -n radarr deployment/radarr
	kubectl rollout restart -n bazarr deployment/bazarr
	kubectl rollout restart -n prowlarr deployment/prowlarr
	kubectl rollout restart -n qbittorrent deployment/qbittorrent
	kubectl rollout restart -n jellyfin deployment/jellyfin
	kubectl rollout restart -n homeassistant deployment/homeassistant
	kubectl rollout restart -n miniflux deployment/miniflux
	kubectl rollout restart -n keel deployment/keel

# List all services
services:
	kubectl get services -A -o wide
