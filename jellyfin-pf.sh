#!/bin/bash
# Jellyfin Tailscale Funnel - Persistent Port-Forward Service
# This keeps the port-forward running in the background

JELLYFIN_NS="jellyfin"
JELLYFIN_SVC="service"
LOCAL_PORT="8096"
LOCAL_BIND="127.0.0.1"

PID_FILE="/tmp/jellyfin-port-forward.pid"
LOG_FILE="/tmp/jellyfin-port-forward.log"

start() {
  if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
      echo "Port-forward already running (PID: $OLD_PID)"
      return 0
    fi
  fi

  echo "Starting Jellyfin port-forward..."
  nohup kubectl port-forward -n $JELLYFIN_NS svc/$JELLYFIN_SVC $LOCAL_PORT:$LOCAL_PORT --address=$LOCAL_BIND > "$LOG_FILE" 2>&1 &
  PID=$!
  echo $PID > "$PID_FILE"
  
  sleep 2
  if curl -s -m 1 http://$LOCAL_BIND:$LOCAL_PORT/ > /dev/null 2>&1; then
    echo "✓ Port-forward started successfully (PID: $PID)"
    return 0
  else
    echo "⚠ Port-forward started but not responding yet"
    sleep 2
    return 0
  fi
}

stop() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      echo "Stopping port-forward (PID: $PID)..."
      kill $PID
      rm "$PID_FILE"
      echo "✓ Port-forward stopped"
    fi
  fi
}

status() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      echo "Port-forward is running (PID: $PID)"
      echo "  Binding: $LOCAL_BIND:$LOCAL_PORT"
      echo "  Service: $JELLYFIN_NS/$JELLYFIN_SVC"
      
      if curl -s -m 1 http://$LOCAL_BIND:$LOCAL_PORT/ > /dev/null 2>&1; then
        echo "  Status: ✓ Responding"
      else
        echo "  Status: ⚠ Not responding"
      fi
    else
      echo "Port-forward process not found (stale PID file)"
      rm "$PID_FILE"
    fi
  else
    echo "Port-forward is not running"
  fi
}

case "${1:-start}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac
