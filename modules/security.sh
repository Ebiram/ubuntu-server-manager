# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: security.sh (System Hardening & Base Configuration - NO SSH)
# ==============================================================================

log_info "Initializing Sub-Module: System Hardening and Core Infrastructure."

# 1. Non-interactive Package Updates & Security Patches
log_info "Updating system package repositories and upgrading core dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get dist-upgrade -y

# Install essential security and administration tools (no SSH-related config)
apt-get install -y ufw fail2ban libpam-tmpdir needrestart ubc htop unattended-upgrades

# 2. Hostname Transformation
read -p "[INPUT] Enter the new fully qualified domain name / hostname (or leave empty to skip): " NEW_HOSTNAME
if [ ! -z "$NEW_HOSTNAME" ]; then
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i "1s/.*/127.0.0.1 localhost $NEW_HOSTNAME/" /etc/hosts
    log_success "Hostname successfully reconfigured to: $NEW_HOSTNAME"
fi

# 3. Sysctl Kernel Network Layer Hardening
log_info "Injecting secure sysctl network parameters..."
SYSCTL_CONF="/etc/sysctl.d/99-security-hardening.conf"
cat << EOF > "$SYSCTL_CONF"
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 5
EOF

sysctl --system > /dev/null
log_success "Sysctl kernel parameters applied."

# 4. Fail2Ban (general activation, no SSH jail)
log_info "Configuring Fail2Ban (generic protection only)..."
systemctl enable fail2ban
systemctl restart fail2ban
log_success "Fail2Ban enabled."

# 5. Unattended Upgrades
log_info "Enabling unattended security updates..."
dpkg-reconfigure -plow unattended-upgrades
log_success "Unattended upgrades enabled."

# 6. Firewall (NO SSH RULES)
log_info "Configuring UFW firewall..."

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

read -p "[INPUT] Input application ports to open (e.g., 80,443): " CUSTOM_PORTS
if [ ! -z "$CUSTOM_PORTS" ]; then
    IFS=',' read -ra PORTS <<< "$CUSTOM_PORTS"
    for port in "${PORTS[@]}"; do
        clean_port=$(echo "$port" | xargs)
        ufw allow "$clean_port"
        log_success "Port opened: $clean_port"
    done
fi

ufw --force enable
ufw status verbose

# 7. Cleanup
log_info "Post-deployment cleanup..."
apt-get autoremove -y && apt-get autoclean -y

log_success "System initialized without SSH stack."

echo "======================================================"
echo "WARNING: Ensure remote access method exists (console/VNC)."
echo "======================================================"
sleep 5
reboot
