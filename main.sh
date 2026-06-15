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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}    UBUNTU ADVANCED SERVER AUTOMATION & HARDENING MATRIX              ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo " 1) Complete Server Initial Configuration & Hardening (Config Server)"
echo " 2) Performance Optimization & Kernel Tuning"
echo " 3) Specific Service Provisioning (PHP, Nginx, MariaDB, Node.js)"
echo " 4) Custom Application Script Deployment (3x-ui, OpenVPN)"
echo " 5) Multi-Server Tunneling & Reverse Proxy Suite (Gost, Xray Reverse)"
echo -e "${CYAN}======================================================================${NC}"
read -p "Select an architecture module [1-5]: " MAIN_CHOICE

case $MAIN_CHOICE in
    1) source "$MODULES_DIR/security.sh" ;;
    2) source "$MODULES_DIR/optimization.sh" ;;
    3) source "$MODULES_DIR/provision.sh" ;;
    4) source "$MODULES_DIR/deploy.sh" ;;
    5) source "$MODULES_DIR/tunnel.sh" ;;
    *) log_error "Invalid selection. Terminating process."; exit 1 ;;
esac
