#!/bin/bash

# ==============================================================================
#  AUTOMATED UBUNTU SERVER INITIAL SECURITY & CONFIGURATION SCRIPT
#  Target OS: Ubuntu 24.04 LTS and higher
#  Description: Modular, highly secure system initialization script.
# ==============================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[ERROR] This script must be run with root or sudo privileges.\e[0m"
    exit 1
fi

# Modern color definitions for output logging
NC='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}    UBUNTU ADVANCED SERVER AUTOMATION & HARDENING MATRIX              ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo " 1) Complete Server Initial Configuration & Hardening (Config Server)"
echo " 2) Performance Optimization & Kernel Tuning (Next Phase)"
echo " 3) Specific Service Provisioning (e.g., PHP, Nginx, LEMP) (Next Phase)"
echo " 4) Custom Application Script Deployment (Next Phase)"
echo -e "${CYAN}======================================================================${NC}"
read -p "Select an architecture module [1-4]: " MAIN_CHOICE

case $MAIN_CHOICE in
    1)
        log_info "Initializing Module 1: System Hardening and Core Infrastructure."
        ;;
    2|3|4)
        log_warn "This architecture module is slated for the next development sprint."
        exit 0
        ;;
    *)
        log_error "Invalid selection. Terminating process."
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# MODULE 1: CORE SERVER CONFIGURATION & SYSTEM HARDENING
# ------------------------------------------------------------------------------

# 1. Non-interactive Package Updates & Security Patches
log_info "Updating system package repositories and upgrading core dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get dist-upgrade -y

# Install essential security and administration tools
apt-get install -y ufw fail2ban libpam-tmpdir needrestart ubc htop unattended-upgrades

# 2. Hostname Transformation
read -p "[INPUT] Enter the new fully qualified domain name / hostname (or leave empty to skip): " NEW_HOSTNAME
if [ ! -z "$NEW_HOSTNAME" ]; then
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i "1s/.*/127.0.0.1 localhost $NEW_HOSTNAME/" /etc/hosts
    log_success "Hostname successfully reconfigured to: $NEW_HOSTNAME"
fi

# 3. Secure Dedicated Deployment User Configuration
read -p "[INPUT] Enter the username for the new administrative/sudo user: " NEW_USER
if [ ! -z "$NEW_USER" ]; then
    # Create user securely with predefined bash shell
    useradd -m -s /bin/bash "$NEW_USER"
    log_info "Assign strict credentials to the new administrative user:"
    passwd "$NEW_USER"
    
    # Append to sudo group
    usermod -aG sudo "$NEW_USER"
    log_success "User '$NEW_USER' provisioned and granted sudo operational privileges."

    # 4. Critical SSH Public Key Sync (Prevents Lockout under No-Password policy)
    read -p "[INPUT] Mirror existing root SSH keys to '$NEW_USER'? Mandatory if disabling passwords (y/n): " COPY_SSH
    if [[ "$COPY_SSH" =~ ^[Yy]$ ]]; then
        USER_SSH_DIR="/home/$NEW_USER/.ssh"
        mkdir -p "$USER_SSH_DIR"
        if [ -f ~/.ssh/authorized_keys ]; then
            cp ~/.ssh/authorized_keys "$USER_SSH_DIR/"
        fi
        chown -R "$NEW_USER":"$NEW_USER" "$USER_SSH_DIR"
        chmod 700 "$USER_SSH_DIR"
        chmod 600 "$USER_SSH_DIR/"* 2>/dev/null
        log_success "SSH architectural cryptographic keys synced to user profile."
    else
        log_warn "Skipping SSH key duplication. Ensure password-less authentication is valid before disconnect."
    fi
fi

# 5. Advanced SSH Daemon Hardening Matrix
log_info "Applying strict cryptographic and protocol hardening layers to SSH daemon..."
SSH_CONFIG="/etc/ssh/sshd_config"
cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"

# Apply zero-trust overrides to the SSH daemon profile
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' "$SSH_CONFIG"
sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSH_CONFIG"
sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' "$SSH_CONFIG"

# Validate SSH configuration syntax before cycling service
sshd -t
if [ $? -eq 0 ]; then
    systemctl restart sshd
    log_success "SSH daemon fortified and service restarted successfully."
else
    log_error "SSH configuration validation failed. Restoring original configuration fallback."
    mv "${SSH_CONFIG}.bak" "$SSH_CONFIG"
    systemctl restart sshd
fi

# 6. Sysctl Kernel Network Layer Hardening (Defends against Spoofing/DoS)
log_info "Injecting secure sysctl network parameters to guard against network exploits..."
SYSCTL_CONF="/etc/sysctl.d/99-security-hardening.conf"
cat << EOF > "$SYSCTL_CONF"
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP echo requests (Ignore Ping / Prevent ICMP Flood)
net.ipv4.icmp_echo_ignore_all = 1

# Do not accept IP source route packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Do not accept ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Mitigate SYN Flood Attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 5
EOF
sysctl --system > /dev/null
log_success "Sysctl kernel parameter matrix compiled and executed active."

# 7. Auto-Configuration of Fail2Ban Defenses
log_info "Configuring Fail2Ban automated brute-force defensive monitoring..."
JAIL_CONF="/etc/fail2ban/jail.local"
cat << EOF > "$JAIL_CONF"
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
findtime = 600
bantime = 3600
EOF
systemctl restart fail2ban
log_success "Fail2Ban active monitoring profile deployed for SSH service."

# 8. Unattended Upgrades Profile (Automated Security Hotfixes)
log_info "Enabling unattended background security updates..."
dpkg-reconfigure -plow unattended-upgrades
log_success "Automated software patching mechanisms registered."

# 9. Firewall Topology Implementation (UFW)
log_info "Resetting firewall profiles and building strict explicit access matrices..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Authorize standard SSH traffic explicitly
ufw allow ssh

# Collect and parse modular ports requested by administrator
read -p "[INPUT] Input custom supplemental application ports to open (e.g., 80,443) [Leave blank to skip]: " CUSTOM_PORTS
if [ ! -z "$CUSTOM_PORTS" ]; then
    IFS=',' read -ra PORTS <<< "$CUSTOM_PORTS"
    for port in "${PORTS[@]}"; do
        clean_port=$(echo "$port" | xargs)
        ufw allow "$clean_port"
        log_success "Firewall access authorized for custom port: $clean_port"
    done
fi

# Force state change activation on firewall
ufw --force enable
log_success "UFW security topology fully online and integrated."
ufw status verbose

# 10. Post-Deployment Purge and Asset Optimizations
log_info "Executing definitive post-deployment dependency optimization..."
apt-get autoremove -y && apt-get autoclean -y

log_success "System architecture initialized and completely hardened."
echo -e "${YELLOW}======================================================================${NC}"
echo -e "${RED}[CRITICAL WARNING] SYSTEM IS SCHEDULED TO SHUTDOWN & REBOOT IN 10 SECONDS.${NC}"
echo -e "${GREEN}Ensure you have access via the newly configured account: '$NEW_USER' using SSH Keys.${NC}"
echo -e "${YELLOW}======================================================================${NC}"

sleep 10
reboot
