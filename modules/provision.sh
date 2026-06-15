# ==============================================================================
#  PROJECT: AUTOMATED SERVER MANAGEMENT SUITE
#  MODULE: provision.sh (Interactive Service Provisioning Suite)
# ==============================================================================

log_info "Initializing Sub-Module: Service Provisioning Suite."

# ------------------------------------------------------------------------------
# SERVICE INSTALLATION FUNCTIONS
# ------------------------------------------------------------------------------

install_nginx() {
    log_info "Installing and configuring Nginx Web Server..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    read -p "[INPUT] Enter the domain name for your website (e.g., domain.com): " SITE_NAME
    if [ ! -z "$SITE_NAME" ]; then
        VHOST_FILE="/etc/nginx/sites-available/$SITE_NAME"
        WEB_ROOT="/var/www/$SITE_NAME"
        
        mkdir -p "$WEB_ROOT"
        chown -R www-data:www-data "$WEB_ROOT"
        chmod -R 755 "$WEB_ROOT"

        # Production-ready Virtual Host for Laravel/WordPress
        cat << EOF > "$VHOST_FILE"
server {
    listen 80;
    listen [::]:80;
    server_name $SITE_NAME www.$SITE_NAME;
    root $WEB_ROOT/public; # Optimized for Laravel structure (fallback to root if WP)

    index index.php index.html index.htm;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock; # Dynamic symlink approach
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
        ln -sf "$VHOST_FILE" "/etc/nginx/sites-enabled/"
        rm -f /etc/nginx/sites-enabled/default
        nginx -t && systemctl restart nginx
        log_success "Virtual Host created for $SITE_NAME. Web root: $WEB_ROOT"
    fi
}

install_php() {
    log_info "Installing PHP with Production extensions for Laravel & WordPress..."
    # On Ubuntu 24.04+, default is PHP 8.3. We will install native production packages.
    apt-get install -y php-fpm php-cli php-mysql php-mbstring php-xml php-bcmath php-curl php-zip php-gd php-intl php-redis php-sqlite3 php-imagick php-opcache

    # Optimize php.ini for production
    PHP_INI_PATH=$(php -i | grep "Loaded Configuration File" | awk '{print $5}')
    if [ -f "$PHP_INI_PATH" ]; then
        sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' "$PHP_INI_PATH"
        sed -i 's/^post_max_size.*/post_max_size = 64M/' "$PHP_INI_PATH"
        sed -i 's/^memory_limit.*/memory_limit = 256M/' "$PHP_INI_PATH"
        sed -i 's/^max_execution_time.*/max_execution_time = 300/' "$PHP_INI_PATH"
        # Enable OPcache
        sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$PHP_INI_PATH"
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' "$PHP_INI_PATH"
    fi
    
    # Generic symlink for Nginx config consistency
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    ln -sf "/var/run/php/php${PHP_VER}-fpm.sock" /var/run/php/php-fpm.sock

    systemctl restart php${PHP_VER}-fpm
    log_success "PHP $PHP_VER with full extensions and production optimizations installed."
}

install_nodejs() {
    log_info "Installing Node.js (LTS version via NodeSource)..."
    apt-get install -y curl
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
    log_success "Node.js version: $(node -v) and NPM version: $(npm -v) installed."
}

install_python() {
    log_info "Installing Python3, Pip, and essential environment setups..."
    apt-get install -y python3 python3-pip python3-venv python3-dev build-essential
    log_success "Python environment successfully provisioned."
}

install_mariadb() {
    log_info "Installing MariaDB Production Server..."
    apt-get install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
    
    # Secure installation presets
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password;"
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('Root_Secure_Password_Change_Me');"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    log_success "MariaDB installed and secured. Temporary root pass set to 'Root_Secure_Password_Change_Me'."
}

install_phpmyadmin() {
    log_info "Installing phpMyAdmin (Secured & Non-interactive)..."
    export DEBIAN_FRONTEND=noninteractive
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    apt-get install -y phpmyadmin
    
    # Link to Nginx default html or link dynamically inside virtual host later
    ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin
    log_success "phpMyAdmin installed. Access linked to default root /phpmyadmin"
}

install_postgresql() {
    log_info "Installing PostgreSQL Server..."
    apt-get install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql
    log_success "PostgreSQL server is up and running."
}

install_redis() {
    log_info "Installing and configuring Redis Cache Server..."
    apt-get install -y redis-server
    
    # Configure production memory management
    REDIS_CONF="/etc/redis/redis.conf"
    if [ -f "$REDIS_CONF" ]; then
        sed -i 's/^maxmemory .*/maxmemory 256mb/' "$REDIS_CONF"
        sed -i 's/^maxmemory-policy .*/maxmemory-policy allkeys-lru/' "$REDIS_CONF"
        # Bind to localhost for security
        sed -i 's/^bind .*/bind 127.0.0.1 ::1/' "$REDIS_CONF"
    fi
    systemctl restart redis-server
    log_success "Redis optimized for low-latency memory operations."
}

install_mail_server() {
    log_info "Installing Postfix Mail Server optimized for Inbox delivery..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Install Postfix as Internet Site
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
    apt-get install -y postfix bsd-mailx
    
    POSTFIX_MAIN="/etc/postfix/main.cf"
    # Basic anti-spam & delivery configs
    echo "biff = no" >> "$POSTFIX_MAIN"
    echo "append_dot_mydomain = no" >> "$POSTFIX_MAIN"
    echo "readme_directory = no" >> "$POSTFIX_MAIN"
    
    systemctl restart postfix
    log_success "Postfix installed for outbound delivery."
    log_warn "CRITICAL: To land in INBOX, you MUST add SPF, DKIM, and DMARC records to your DNS provider."
}

# ------------------------------------------------------------------------------
# INTERACTIVE SUB-MENU LOGIC
# ------------------------------------------------------------------------------

show_provision_menu() {
    while true; do
        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${CYAN}    SUB-MENU: SERVICE PROVISIONING ARCHITECTURE                        ${NC}"
        echo -e "${CYAN}======================================================================${NC}"
        echo " 1) Install Nginx Web Server (with Virtual Host wizard)"
        echo " 2) Install PHP Suite (Laravel & WordPress Production ready)"
        echo " 3) Install Node.js (LTS Runtime)"
        echo " 4) Install Python Environment (Pip & Venv)"
        echo " 5) Install MariaDB Database (Secured Server)"
        echo " 6) Install phpMyAdmin Console"
        echo " 7) Install PostgreSQL Database Server"
        echo " 8) Install Redis Cache Server (Memory Optimized)"
        echo " 9) Install Postfix Outbound Mail Server"
        echo " 10) Back to Main Menu"
        echo -e "${CYAN}======================================================================${NC}"
        read -p "Select a software package to provision [1-10]: " SUB_CHOICE

        case $SUB_CHOICE in
            1) install_nginx ;;
            2) install_php ;;
            3) install_nodejs ;;
            4) install_python ;;
            5) install_mariadb ;;
            6) install_phpmyadmin ;;
            7) install_postgresql ;;
            8) install_redis ;;
            9) install_mail_server ;;
            10) log_info "Returning to main menu suite."; break ;;
            *) log_error "Invalid item selection." ;;
         photocopy
        esac
    done
}

# Invoke the sub-menu UI entrypoint
show_provision_menu
