# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: tunnel.sh (Secure Reverse Proxy & Multi-Server Tunneling Matrix)
# ==============================================================================

log_info "Initializing Sub-Module: Multi-Server Tunneling & Reverse Proxy."

# Ensure automated core dependencies are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    apt-get install -y jq curl iperf3
fi

# ------------------------------------------------------------------------------
# TUNNEL CONFIGURATION FUNCTIONS
# ------------------------------------------------------------------------------

setup_gost_tunnel() {
    log_info "Installing and deploying GOST (Generic Oriented String Tunnel)..."
    
    # Fetch latest GOST binary from GitHub releases
    LATEST_GOST=$(curl -s https://api.github.com/repos/ginuerzh/gost/releases/latest | jq -r '.tag_name')
    log_info "Downloading GOST version $LATEST_GOST..."
    
    # Architecture check
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        GOST_URL="https://github.com/ginuerzh/gost/releases/download/${LATEST_GOST}/gost_${LATEST_GOST:1}_linux_amd64.tar.gz"
    else
        GOST_URL="https://github.com/ginuerzh/gost/releases/download/${LATEST_GOST}/gost_${LATEST_GOST:1}_linux_arm64.tar.gz"
    fi

    curl -L "$GOST_URL" -o /tmp/gost.tar.gz
    tar -xf /tmp/gost.tar.gz -C /usr/local/bin/ gost
    chmod +x /usr/local/bin/gost
    rm -f /tmp/gost.tar.gz

    echo -e "\nSelect Server Role for GOST Tunnel:"
    echo "1) IRAN Server (Inbound / Reverse Entry)"
    echo "2) KHARIJ Server (Outbound / Destination End)"
    read -p "Select Role [1-2]: " GOST_ROLE

    if [ "$GOST_ROLE" = "1" ]; then
        read -p "[INPUT] Enter Remote KHARIJ Server IP: " KHARIJ_IP
        read -p "[INPUT] Enter Tunnel Port (e.g., 8443): " TUNNEL_PORT
        read -p "[INPUT] Enter Local Service Port to Forward (e.g., 443): " LOCAL_PORT
        
        # Create Systemd Service for persistence
        cat << EOF > /etc/systemd/system/gost-tunnel.service
[Unit]
Description=GOST Tunnel Iran Entry Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost -L=tcp://:$LOCAL_PORT -F=grpc://$KHARIJ_IP:$TUNNEL_PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        ufw allow "$LOCAL_PORT"
        
    elif [ "$GOST_ROLE" = "2" ]; then
        read -p "[INPUT] Enter Tunnel Port to Listen on (e.g., 8443): " TUNNEL_PORT
        read -p "[INPUT] Enter Target Destination Port (e.g., 2083 or 443): " TARGET_PORT
        
        cat << EOF > /etc/systemd/system/gost-tunnel.service
[Unit]
Description=GOST Tunnel Kharij Destination Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost -L=grpc://:$TUNNEL_PORT/127.0.0.1:$TARGET_PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        ufw allow "$TUNNEL_PORT"
    fi

    systemctl daemon-reload
    systemctl enable gost-tunnel
    systemctl start gost-tunnel
    log_success "GOST Systemd Service deployed and initiated."
}

setup_xray_reverse() {
    log_info "Deploying Native Xray Core Reverse Proxy Tunnel..."
    
    # Install official Xray Core architecture
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
    
    echo -e "\nSelect Server Role for Xray Reverse Tunnel:"
    echo "1) IRAN Server (Bridge Mode)"
    echo "2) KHARIJ Server (Portal Mode)"
    read -p "Select Role [1-2]: " XRAY_ROLE

    if [ "$XRAY_ROLE" = "1" ]; then
        read -p "[INPUT] Enter KHARIJ Server IP: " KHARIJ_IP
        read -p "[INPUT] Enter Bridge Communication Port (e.g., 9000): " BRIDGE_PORT
        
        # Bridge Config structure
        cat << EOF > /usr/local/etc/xray/config.json
{
  "reverse": {
    "bridges": [{ "tag": "bridge", "domain": "tunnel.local" }]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [{
          "address": "$KHARIJ_IP",
          "port": $BRIDGE_PORT,
          "users": [{ "id": "9a7b744a-d8c5-4f40-8c26-5883d6a99fc5" }]
        }]
      },
      "tag": "interconnect"
    }
  ],
  "routing": {
    "rules": [{ "type": "field", "inboundTag": ["bridge"], "outboundTag": ["interconnect"] }]
  }
}
EOF
        ufw allow "$BRIDGE_PORT"

    elif [ "$XRAY_ROLE" = "2" ]; then
        read -p "[INPUT] Enter Portal Communication Port (e.g., 9000): " PORTAL_PORT
        read -p "[INPUT] Enter External User Inbound Port (e.g., 443): " USER_PORT

        # Portal Config structure
        cat << EOF > /usr/local/etc/xray/config.json
{
  "reverse": {
    "portals": [{ "tag": "portal", "domain": "tunnel.local" }]
  },
  "inbounds": [
    {
      "port": $PORTAL_PORT,
      "protocol": "vmess",
      "settings": { "clients": [{ "id": "9a7b744a-d8c5-4f40-8c26-5883d6a99fc5" }] },
      "tag": "interconnect"
    },
    {
      "port": $USER_PORT,
      "protocol": "shadowsocks",
      "settings": { "method": "aes-256-gcm", "password": "SecurePasswordMatters" },
      "tag": "external_traffic"
    }
  ],
  "routing": {
    "rules": [{ "type": "field", "inboundTag": ["external_traffic"], "outboundTag": ["portal"] }]
  }
}
EOF
        ufw allow "$PORTAL_PORT"
        ufw allow "$USER_PORT"
    fi

    systemctl restart xray
    log_success "Xray Core Reverse Routing configuration initialized."
}

test_tunnel_diagnostics() {
    log_info "Launching Active Matrix Network Diagnostics..."
    read -p "[INPUT] Enter Target Server IP to evaluate connection: " TARGET_IP
    
    log_info "Executing Low-Level Latency Probe (ICMP Ping)..."
    ping -c 4 "$TARGET_IP"
    
    echo -e "\nWould you like to initiate a raw throughput capacity test (iperf3)? (y/n)"
    read -p "[INPUT]: " RUN_IPERF
    if [[ "$RUN_IPERF" =~ ^[Yy]$ ]]; then
        echo "1) Start as Listener / Server Node"
        echo "2) Start as Active Client Benchmarker"
        read -p "Select role: " IPERF_ROLE
        
        if [ "$IPERF_ROLE" = "1" ]; then
            log_warn "Starting iperf3 daemon. Allow port 5201 in UFW firewall if necessary. Press Ctrl+C to terminate."
            iperf3 -s
        else
            log_info "Connecting to network benchmark pool on $TARGET_IP..."
            iperf3 -c "$TARGET_IP"
        fi
    fi
}

# ------------------------------------------------------------------------------
# INTERACTIVE SUB-MENU LOGIC
# ------------------------------------------------------------------------------

show_tunnel_menu() {
    while true; do
        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${CYAN}    SUB-MENU: REVERSE PROXY & MULTI-SERVER TUNNELING                   ${NC}"
        echo -e "${CYAN}======================================================================${NC}"
        echo " 1) Deploy High-Performance GOST Tunnel (gRPC Multiplexing)"
        echo " 2) Deploy Xray Core Native Reverse Proxy (Zero-Trust Model)"
        echo " 3) Execute Tunnel Link Diagnostics (Latency & iperf3 Benchmark)"
        echo " 0) Back to Main Menu"
        echo -e "${CYAN}======================================================================${NC}"
        read -p "Select a tunneling topology [0-3]: " TUNNEL_CHOICE

        case $TUNNEL_CHOICE in
            1) setup_gost_tunnel ;;
            2) setup_xray_reverse ;;
            3) test_tunnel_diagnostics ;;
            0) log_info "Returning to main menu suite."; break ;;
            *) log_error "Invalid selection item." ;;
        esac
    done
}

show_tunnel_menu
