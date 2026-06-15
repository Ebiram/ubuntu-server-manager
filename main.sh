#!/bin/bash

# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  FILE: main.sh (Core Orchestrator)
#  Target OS: Ubuntu 24.04 LTS and higher
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[ERROR] This script must be run with root or sudo privileges.\e[0m"
    exit 1
fi

export NC='\e[0m'
export RED='\e[31m'
export GREEN='\e[32m'
export YELLOW='\e[33m'
export BLUE='\e[34m'
export CYAN='\e[36m'

export -f echo

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

export -f log_info log_success log_warn log_error

# Resolve the absolute path where THIS script is actually located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

trigger_self_installation() {
    log_info "Initiating Global System Installation Pipeline..."
    
    TARGET_SYSTEM_DIR="/srv/ubuntu-aio-server-manager"
    
    # 1. Clone to persistent state directory if run from temp folder
    if [ "$SCRIPT_DIR" != "$TARGET_SYSTEM_DIR" ]; then
        mkdir -p "$TARGET_SYSTEM_DIR"
        cp -r "$SCRIPT_DIR/"* "$TARGET_SYSTEM_DIR/"
        log_info "Project assets cloned to a persistent directory: $TARGET_SYSTEM_DIR"
    fi

    # 2. Grant structural execution permissions recursively
    chmod +x "$TARGET_SYSTEM_DIR/main.sh"
    chmod +x "$TARGET_SYSTEM_DIR/modules/"*.sh 2>/dev/null
    
    # 3. Create a Symlink inside /usr/local/bin to enable direct execution
    ln -sf "$TARGET_SYSTEM_DIR/main.sh" /usr/local/bin/server-manager
    
    log_success "Installation Complete! You can now type: server-manager"
}

clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}    UBUNTU ADVANCED SERVER AUTOMATION & HARDENING MATRIX              ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo " 1) Complete Server Initial Configuration & Hardening (Config Server)"
echo " 2) Performance Optimization & Kernel Tuning"
echo " 3) Specific Service Provisioning (PHP, Nginx, MariaDB, Node.js)"
echo " 4) Custom Application Script Deployment (3x-ui, OpenVPN)"
echo " 5) Multi-Server Tunneling & Reverse Proxy Suite (Gost, Xray Reverse)"
echo " 6) System Environment Localization & Tuning (DNS, Timezone, ZRAM)"
echo " 7) Install this Suite Permanently to Server Local Hardware"
echo -e "${CYAN}======================================================================${NC}"
read -p "Select an architecture module [1-7]: " MAIN_CHOICE

# Helper function to source modules safely
run_module() {
    local module_path="$MODULES_DIR/$1"
    if [ -f "$module_path" ]; then
        # Ensure it has execution rights dynamically
        chmod +x "$module_path"
        source "$module_path"
    else
        log_error "Module not found at: $module_path"
        exit 1
    fi
}

case $MAIN_CHOICE in
    1) run_module "security.sh" ;;
    2) run_module "optimization.sh" ;;
    3) run_module "provision.sh" ;;
    4) run_module "deploy.sh" ;;
    5) run_module "tunnel.sh" ;;
    6) run_module "system_env.sh" ;;
    7) trigger_self_installation ;;
    *) log_error "Invalid selection. Terminating process."; exit 1 ;;
esac
