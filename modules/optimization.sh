# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: optimization.sh (Performance Tuning for Proxy, Web & Load Balancer)
# ==============================================================================

log_info "Initializing Sub-Module: Performance Optimization & Kernel Tuning."

# 1. Increase System File Descriptors (Max Open Files Limit)
log_info "Optimizing system-wide file descriptor limits..."
LIMITS_CONF="/etc/security/limits.conf"

# Backup existing limits
cp "$LIMITS_CONF" "${LIMITS_CONF}.bak"

# Append high-capacity limits for all users
cat << EOF >> "$LIMITS_CONF"
* soft nofile 1000000
* hard nofile 1000000
root soft nofile 1000000
root hard nofile 1000000
EOF

# Systemd specific limits for modern services (Nginx, HAProxy, Xray)
mkdir -p /etc/systemd/system.conf.d
cat << EOF > /etc/systemd/system.conf.d/limits.conf
[Manager]
DefaultLimitNOFILE=1000000
EOF

log_success "File descriptor and resource limits expanded to 1,000,000."

# 2. Advanced Network Stack Tuning (sysctl)
log_info "Injecting high-throughput network stack configurations..."
OPT_SYSCTL="/etc/sysctl.d/98-edge-performance.conf"

cat << EOF > "$OPT_SYSCTL"
# Maximize network queue sizes for high concurrent connections
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 100000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Optimize TCP buffer sizes
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Fast recycling of dead sockets and memory management
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_max_syn_backlog = 65535

# Virtual Memory (VM) Tuning - Prioritize RAM over disk Swap
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
EOF

sysctl --system > /dev/null
log_success "Network stack parameters optimized successfully."

# 3. Enable Google BBR Congestion Control
log_info "Verifying and enabling Google BBR Congestion Control..."

# Inject BBR modules into sysctl
cat << EOF >> "$OPT_SYSCTL"
# Enable BBR TCP Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl --system > /dev/null

# Runtime validation of BBR
CURRENT_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [ "$CURRENT_CC" = "bbr" ]; then
    log_success "Google BBR Congestion Control is now active."
else
    log_warn "BBR configuration staged. It will initialize completely upon system reboot."
fi

# 4. Ephemeral Port Range Expansion
log_info "Expanding ephemeral port allocations for reverse proxies and balancers..."
echo "net.ipv4.ip_local_port_range = 1024 65535" >> "$OPT_SYSCTL"
sysctl --system > /dev/null
log_success "Local port range extended (1024-65535)."

echo -e "${YELLOW}======================================================================${NC}"
echo -e "${GREEN}[✓] Performance optimizations have been applied successfully.${NC}"
echo -e "${YELLOW}Note: Some core limits require a system reboot or session restart to reflect.${NC}"
echo -e "${YELLOW}======================================================================${NC}"
