# Jellyfin Tailscale Funnel - Implementation Summary

## Current Status: ✓ READY

### ✓ What's Done
1. **Port-Forward Running**: Jellyfin K8s service is accessible at `127.0.0.1:8096`
   - Process: kubectl port-forward (PID: 3162252)
   - Status: Active and responding
   - Accessibility: ✓ Verified

2. **User Systemd Service Created**: `~/.config/systemd/user/jellyfin-port-forward.service`
   - This will automatically restart the port-forward if it stops
   - Persists across user sessions

3. **Files Created**:
   - `jellyfin-funnel.service` - System-level service (needs sudo to deploy)
   - `jellyfin-pf.sh` - Manual port-forward control script
   - `quick-setup-jellyfin-funnel.sh` - One-command setup script (needs sudo)
   - `setup-jellyfin-funnel-full.sh` - Full setup script (needs sudo)

### ⏳ What's Needed (Requires Sudo)
Configure Tailscale Funnel to expose Jellyfin publicly. Run ONE of:

**Option A: Allow non-sudo Funnel (recommended)**
```bash
sudo tailscale set --operator=$USER
tailscale funnel --bg 127.0.0.1:8096
```

**Option B: Use sudo directly**
```bash
sudo tailscale funnel --bg 127.0.0.1:8096
```

**Option C: Run complete setup script**
```bash
bash ~/homelab/quick-setup-jellyfin-funnel.sh
```

## Verification

### Local Access (from this machine)
```bash
curl http://127.0.0.1:8096/
# Expected: 302 redirect to /web/
```

### Tailnet Access (from Tailnet devices)
```bash
curl http://100.97.153.46:8096/
# After setting up port-forward
```

### Public Funnel Access
After running Tailscale Funnel setup:
```bash
tailscale funnel status
# Will show the public funnel URL
```

## Management Commands

### Check Port-Forward Status
```bash
# User systemd service
systemctl --user status jellyfin-port-forward.service

# View logs
journalctl --user -u jellyfin-port-forward.service -f
```

### Check Tailscale Funnel Status
```bash
tailscale funnel status
```

### Stop Tailscale Funnel
```bash
sudo tailscale funnel reset 127.0.0.1:8096
```

## Architecture

```
┌─────────────────────────────────────────┐
│ Jellyfin Container (K8s)                │
│ Port: 8096                              │
└────────────────┬────────────────────────┘
                 │
                 │ K8s ClusterIP Service
                 │ 10.43.78.70:8096
                 │
┌────────────────▼────────────────────────┐
│ kubectl port-forward (host)             │
│ Status: ✓ RUNNING                       │
│ Bind: 127.0.0.1:8096                    │
└────────────────┬────────────────────────┘
                 │
                 │
┌────────────────▼────────────────────────┐
│ Tailscale Funnel (requires sudo)        │
│ Status: ⏳ NEEDS SETUP                  │
│ Makes it publicly accessible             │
└─────────────────────────────────────────┘
```

## Next Steps

1. **Enable Funnel** (requires sudo password once):
   ```bash
   sudo tailscale set --operator=$USER
   tailscale funnel --bg 127.0.0.1:8096
   ```

2. **Verify** it's working:
   ```bash
   tailscale funnel status
   ```

3. **Test** the public URL from the status output

## Troubleshooting

### Port-Forward Not Working
```bash
# Check if kubectl can access the cluster
kubectl get svc -n jellyfin

# Manually test
kubectl port-forward -n jellyfin svc/service 8096:8096

# View systemd service logs
journalctl --user -u jellyfin-port-forward.service -n 50
```

### Tailscale Funnel Not Working
```bash
# Check Tailscale status
tailscale status

# Verify operator permission
sudo tailscale set --operator=$USER

# Enable funnel
sudo tailscale funnel --bg 127.0.0.1:8096

# Check status
tailscale funnel status
```

### Port 8096 Already in Use
```bash
# Find what's using it
lsof -i :8096

# Kill if needed (replace PID with actual PID)
kill -9 <PID>

# Restart service
systemctl --user restart jellyfin-port-forward.service
```

## Security Notes

- Port-forward binds to `127.0.0.1:8096` (only local, not exposed to network)
- Tailscale Funnel requires Tailscale admin or operator permissions
- No K8s manifests were changed - minimal surface area
- Jellyfin container unchanged - no security implications
