#!/bin/bash

# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  FILE: main.sh (Core Orchestrator)
#  Target OS: Ubuntu 24.04 LTS and higher
# ==============================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[ERROR] This script must be run with root or sudo privileges.\e[0m"
    exit 1
fi

# Export global environment configurations for child modules
export NC='\e[0m'
export RED='\e[31m'
export GREEN='\e[32m'
export YELLOW='\e[33m'
export BLUE='\e[34m'
export CYAN='\e[36m'

export -f echo

# Global logging utilities
log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

export -f log_info log_success log_warn log_error

# Absolute path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

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
        if [ -f "$MODULES_DIR/security.sh" ]; then
            source "$MODULES_DIR/security.sh"
        else
            log_error "Security module not found at: $MODULES_DIR/security.sh"
            exit 1
        fi
        ;;
    2)
        if [ -f "$MODULES_DIR/optimization.sh" ]; then
            source "$MODULES_DIR/optimization.sh"
        else
            log_error "Optimization module not found at: $MODULES_DIR/optimization.sh"
            exit 1
        fi
        ;;
    3|4)
        log_warn "This architecture module is slated for the next development sprint."
        exit 0
        ;;
    *)
        log_error "Invalid selection. Terminating process."
        exit 1
        ;;
esac
