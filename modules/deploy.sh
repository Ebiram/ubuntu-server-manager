# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: deploy.sh (Custom Application & Proxy Deployment Suite)
# ==============================================================================

log_info "Initializing Sub-Module: Custom Application Script Deployment."

# ------------------------------------------------------------------------------
# APPLICATION DEPLOYMENT FUNCTIONS
# ------------------------------------------------------------------------------

install_3x_ui() {
    log_info "Downloading and executing the official 3x-ui (MHSanaei) installation script..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        log_info "Installing curl dependency..."
        apt-get install -y curl
    fi

    # Execute the core 3x-ui installer
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    
    if [ $? -eq 0 ]; then
        log_success "3x-ui Panel has been deployed successfully."
        log_warn "Remember to allow your custom 3x-ui port in the UFW firewall if needed (Module 1)."
    else
        log_error "Failed to execute 3x-ui installation script."
    fi
}

install_openvpn() {
    log_info "Fetching the optimized OpenVPN installation script (Angristan architecture)..."
    
    OVPN_INSTALLER="/tmp/openvpn-install.sh"
    
    # Download the standard production-ready installer from Angristan
    curl -fsSL https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -o "$OVPN_INSTALLER"
    chmod +x "$OVPN_INSTALLER"

    log_warn "Launching the OpenVPN interactive wizard. Please follow the terminal prompts."
    
    # Execute the installer interactively so you can define your custom ports/DNS
    $OVPN_INSTALLER

    if [ $? -eq 0 ]; then
        log_success "OpenVPN server setup complete."
    else
        log_error "OpenVPN installation process encountered an error."
    fi
    
    # Clean up the installation asset from tmp
    rm -f "$OVPN_INSTALLER"
}

# ------------------------------------------------------------------------------
# INTERACTIVE SUB-MENU LOGIC
# ------------------------------------------------------------------------------

show_deploy_menu() {
    while true; do
        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${CYAN}    SUB-MENU: CUSTOM APPLICATION DEPLOYMENT                            ${NC}"
        echo -e "${CYAN}======================================================================${NC}"
        echo " 1) Install 3x-ui Panel (Xray Management Platform)"
        echo " 2) Install OpenVPN Server (Angristan Secured Script)"
        echo " 0) Back to Main Menu"
        echo -e "${CYAN}======================================================================${NC}"
        read -p "Select an application deployment routine [1-3]: " APP_CHOICE

        case $APP_CHOICE in
            1) install_3x_ui ;;
            2) install_openvpn ;;
            0) log_info "Returning to main menu suite."; break ;;
            *) log_error "Invalid item selection." ;;
        esac
    done
}

# Invoke the sub-menu UI entrypoint
show_deploy_menu
