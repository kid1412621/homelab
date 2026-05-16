#!/bin/bash
# K3s Lease Health Monitor
# Detects lease proliferation and alerts before database bloat occurs
# Run via cron: */5 * * * * /usr/local/bin/k3s-lease-monitor.sh

set -eou pipefail

DB_PATH="/var/lib/rancher/k3s/server/db/state.db"
ALERT_THRESHOLD=1000  # Alert if lease count exceeds this
LOG_FILE="/var/log/k3s-lease-monitor.log"
ALERT_EMAIL="admin@homelab.local"

# Check if k3s DB exists
if [[ ! -f "$DB_PATH" ]]; then
    echo "[$(date)] K3s database not found at $DB_PATH" >> "$LOG_FILE"
    exit 0
fi

# Query lease entry count using sqlite3
if ! command -v sqlite3 &> /dev/null; then
    echo "[$(date)] sqlite3 not installed, skipping lease monitoring" >> "$LOG_FILE"
    exit 0
fi

# Get lease counts by prefix (the smoking gun from the incident)
LEASE_COUNT=$(sudo sqlite3 "$DB_PATH" \
    "SELECT COUNT(*) FROM kine WHERE name LIKE '/registry/leases/%';" 2>/dev/null | tr -d ' ' || echo "0")

MASTER_LEASE_COUNT=$(sudo sqlite3 "$DB_PATH" \
    "SELECT COUNT(*) FROM kine WHERE name LIKE '/registry/masterleases/%';" 2>/dev/null | tr -d ' ' || echo "0")

# Ensure values are integers (strip whitespace)
LEASE_COUNT=${LEASE_COUNT%%[!0-9]*}
MASTER_LEASE_COUNT=${MASTER_LEASE_COUNT%%[!0-9]*}
LEASE_COUNT=${LEASE_COUNT:-0}
MASTER_LEASE_COUNT=${MASTER_LEASE_COUNT:-0}

TOTAL_LEASES=$((LEASE_COUNT + MASTER_LEASE_COUNT))
DB_SIZE=$(du -sh "$DB_PATH" 2>/dev/null | cut -f1)

# Log current state
echo "[$(date)] Lease Monitor - Regular: $LEASE_COUNT | Master: $MASTER_LEASE_COUNT | Total: $TOTAL_LEASES | DB Size: $DB_SIZE" >> "$LOG_FILE"

# Alert if threshold exceeded
if [ "$TOTAL_LEASES" -gt "$ALERT_THRESHOLD" ]; then
    ALERT_MSG="⚠️  CRITICAL: K3s lease proliferation detected!
    
Lease Counts:
  - /registry/leases/: $LEASE_COUNT
  - /registry/masterleases/: $MASTER_LEASE_COUNT
  - Total: $TOTAL_LEASES
  - Database Size: $DB_SIZE

Action Required:
1. Check for rogue custom controllers creating ephemeral leases
2. Verify all workloads use static lease names for leader election
3. Consider restarting k3s if leases continue growing uncontrollably

See /var/log/k3s-lease-monitor.log for historical data."
    
    echo "[$(date)] ALERT: Lease count ($TOTAL_LEASES) exceeded threshold ($ALERT_THRESHOLD)" >> "$LOG_FILE"
    
    # Send alert (customize transport as needed)
    echo "$ALERT_MSG" | mail -s "K3s Lease Alert - $TOTAL_LEASES entries" "$ALERT_EMAIL" 2>/dev/null || \
    logger -t k3s-lease-monitor "$ALERT_MSG"
fi

# Top 5 lease prefixes (for debugging)
echo "[$(date)] Top lease prefixes:" >> "$LOG_FILE"
sudo sqlite3 "$DB_PATH" \
    "SELECT substr(name, 1, 35) as prefix, COUNT(*) as count FROM kine WHERE name LIKE '/registry/leases%' OR name LIKE '/registry/masterleases%' GROUP BY 1 ORDER BY 2 DESC LIMIT 5;" 2>/dev/null >> "$LOG_FILE" || true

exit 0
