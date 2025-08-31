#!/bin/sh
while true; do
echo "Clearing old logs..."
> /mnt/tmp/net-info.log
> /mnt/tmp/node-info.log

echo "===== $(date) (cron-runner container) =====" >> /mnt/tmp/manual-cron-log.log
echo "Hostname: $(hostname)"  >> /mnt/tmp/manual-cron-log.log
ip a >> /mnt/tmp/net-info.log
ip r >> /mnt/tmp/net-info.log

echo "captured node info" >> /mnt/tmp/manual-cron-log.log
kubectl get nodes -o wide >> /mnt/tmp/node-info.log 2>&1
PRIMARY_IF=$(ip route | awk '/default/ {print $5}' | head -n1)
node_info=$(kubectl get nodes -o wide)
ip_only=$(echo "$node_info" | grep $(hostname) | awk '{print $6}')

echo "IP Address: $ip_only" 

if [ -z "$PRIMARY_IF" ]; then
    echo "ERROR: Could not determine primary interface."
    exit 1
fi

# Get the IP address and prefix
PRIMARY_IP=$(ip -o -f inet addr show "$PRIMARY_IF" | awk '{print $4}' | head -n1)

# Get the gateway
GATEWAY=$(ip route | awk '/default/ {print $3}' | head -n1)

echo "Primary Interface: $PRIMARY_IF"
echo "Primary IP (with CIDR): $PRIMARY_IP"
echo "Default Gateway: $GATEWAY"

INTERFACE=$PRIMARY_IF
STATIC_IP=$ip_only
GATEWAY=$GATEWAY
LOGFILE="/mnt/tmp/ensure-ip.log"

echo "[START] Running ensure-ip at $(date)" >> "$LOGFILE"

# Resolve the real interface name if INTERFACE is not available
if ! ip link show "$INTERFACE" &>/dev/null; then
    ALT_IF=$(ip -o link | awk -F': ' "/altname $INTERFACE/ {print \$2}" | head -n1)
    if [ -n "$ALT_IF" ]; then
        echo "[WARN] Interface $INTERFACE not found, using altname $ALT_IF instead." >> "$LOGFILE"
        REAL_IF="$ALT_IF"
    else
        echo "[ERROR] Interface $INTERFACE and its altname not found. Exiting." >> "$LOGFILE"
        exit 1
    fi
else
    REAL_IF="$INTERFACE"
fi

# Extract just the IP portion from STATIC_IP (e.g., 192.168.1.100 from 192.168.1.100/24)
IP_ONLY=$(echo "$STATIC_IP" | cut -d'/' -f1)

# If the IP is not assigned yet, apply it and set routes
if ! ip addr show "$REAL_IF" | grep -q "$IP_ONLY"; then
    echo "[INFO] IP not found on $REAL_IF, assigning $STATIC_IP..." >> "$LOGFILE"
    ip addr flush dev "$REAL_IF"
    ip addr add "$STATIC_IP" dev "$REAL_IF"
    ip link set "$REAL_IF" up
    sleep 1

    # Add gateway route (in case of /32 or manual routing)
    ip route add "$GATEWAY" dev "$REAL_IF" 2>> "$LOGFILE" || echo "[INFO] Route to gateway may already exist." >> "$LOGFILE"

    # Add default route if missing
    if ! ip route | grep -q "default via $GATEWAY"; then
        ip route add default via "$GATEWAY" dev "$REAL_IF"
        echo "[INFO] Default route added." >> "$LOGFILE"
    else
        echo "[INFO] Default route already exists." >> "$LOGFILE"
    fi
else
    echo "[INFO] IP $STATIC_IP already assigned to $REAL_IF." >> "$LOGFILE"
fi

echo "[END] Completed at $(date)" >> "$LOGFILE"


sleep 30
done