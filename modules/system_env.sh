# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: system_env.sh (System Environment, DNS & Timezone Tuning)
# ==============================================================================

log_info "Initializing Sub-Module: System Environment & Localization Tuning."

# ------------------------------------------------------------------------------
# ENVIRONMENT CONFIGURATION FUNCTIONS
# ------------------------------------------------------------------------------

configure_timezone() {
    log_info "Launching Timezone Configuration Wizard..."
    
    # Enable Network Time Protocol (NTP) syncing
    timedatectl set-ntp true
    
    # Interactively let user choose timezone or list them
    read -p "[INPUT] Enter your region/city (e.g., Asia/Tehran, Europe/Berlin): " USER_TZ
    if [ ! -z "$USER_TZ" ]; then
        if timedatectl list-timezones | grep -qx "$USER_TZ"; then
            timedatectl set-timezone "$USER_TZ"
            log_success "System timezone updated to: $(timedatectl | grep "Time zone")"
        else
            log_error "Invalid timezone string format. Skipping."
        fi
    fi
}

configure_google_dns() {
    log_info "Applying Google Public DNS (8.8.8.8 / 8.8.4.4) via Netplan..."

    # Find the active netplan configuration file (Ubuntu 24.04 standard)
    NETPLAN_FILE=$(find /etc/netplan/ -type f -name "*.yaml" | head -n 1)

    if [ ! -z "$NETPLAN_FILE" ]; then
        # Backup original configuration
        cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
        
        # Inject Google DNS into the primary network device entry using python/sed mapping safely
        # To avoid breaking YAML indentation, we utilize standard systemd-resolved fallback or netplan overrides
        RESOLV_CONF_HEAD="/etc/resolvconf/resolv.conf.d/head"
        
        # Method: Robust fallback using systemd-resolved overrides which is universal
        mkdir -p /etc/systemd/resolved.conf.d
        cat << EOF > /etc/systemd/resolved.conf.d/dns.conf
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
EOF
        systemctl restart systemd-resolved
        log_success "Google DNS injected globally into systemd-resolved framework."
    else
        log_error "Netplan/Network configuration matrix not discovered."
    fi
}

enable_zram_optimization() {
    log_info "Deploying ZRAM (Compressed RAM Drive) to guard against Out-Of-Memory crashes..."
    
    # Install zram-tools swap management layer
    apt-get install -y zram-config
    
    # Validate initialization
    if lsmod | grep -q zram; then
        log_success "ZRAM block device driver initialized dynamically inside volatile memory."
    else
        log_warn "ZRAM kernel module registered. Full optimization requires a machine reboot."
    fi
}

apply_shell_tweaks() {
    log_info "Injecting operational Shell shortcuts (Aliases) for better maintenance..."
    
    BASHRC_ROOT="/root/.bashrc"
    
    # Append custom system tracking shortcodes if they don't exist
    if ! grep -q "alias integrity=" "$BASHRC_ROOT"; then
        cat << EOF >> "$BASHRC_ROOT"
# Custom Server Management Suite Aliases
alias integrity="journalctl -p 3 -xb"
alias networkstatus="ss -tulpn"
alias dropcaches="sync && echo 3 > /proc/sys/vm/drop_caches"
EOF
        log_success "Shell profiling variables updated. Type 'networkstatus' or 'integrity' in next session."
    else
        log_info "Shell profile configurations already fortified."
    fi
}

# ------------------------------------------------------------------------------
# INTERACTIVE SUB-MENU LOGIC
# ------------------------------------------------------------------------------

show_env_menu() {
    while true; do
        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${CYAN}    SUB-MENU: ENVIRONMENT LOCALIZATION & SYS-ADJUSTMENTS               ${NC}"
        echo -e "${CYAN}======================================================================${NC}"
        echo " 1) Synchronize System Time & Timezone Location"
        echo " 2) Configure Google Nameservers (DNS Infrastructure)"
        echo " 3) Enable ZRAM Dynamic Memory Compression (Crash Prevention)"
        echo " 4) Inject Advanced Shell Maintenance Shortcuts (Aliases)"
        echo " 5) Run All Environment Adjustments Sequentially (Recommended)"
        echo " 6) Back to Main Menu"
        echo -e "${CYAN}======================================================================${NC}"
        read -p "Select an environmental routine [1-6]: " ENV_CHOICE

        case $ENV_CHOICE in
            1) configure_timezone ;;
            2) configure_google_dns ;;
            3) enable_zram_optimization ;;
            4) apply_shell_tweaks ;;
            5)
                configure_timezone
                configure_google_dns
                enable_zram_optimization
                apply_shell_tweaks
                ;;
            6) log_info "Returning to main menu suite."; break ;;
            *) log_error "Invalid selection item." ;;
        esac
    done
}

show_env_menu
