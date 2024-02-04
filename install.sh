#!/bin/bash

# Function to install the proxy
install_proxy() {
    echo "Installing the proxy..."
    {
        rm -f /usr/bin/proxy
        curl -s -L -o /usr/bin/proxy https://raw.githubusercontent.com/PhoenixxZ2023/proxy/main/proxy
        chmod +x /usr/bin/proxy
    } > /dev/null 2>&1
    echo "Proxy installed successfully."
}

# Function to uninstall the proxy
uninstall_proxy() {
    echo -e "\nUninstalling the proxy..."

    # Find and remove all proxy service files
    service_files=$(find /etc/systemd/system -name 'proxy-*.service')
    for service_file in $service_files; do
        service_name=$(basename "$service_file")
        service_name=${service_name%.service}

        # Check if the service is active before stopping and disabling
        if systemctl is-active "$service_name" &> /dev/null; then
            systemctl stop "$service_name"
            systemctl disable "$service_name"
        fi

        rm -f "$service_file"
        echo "Service $service_name stopped, and service file removed: $service_file"
    done

    # Remove the proxy binary file
    rm -f /usr/bin/proxy

    echo "Proxy uninstalled successfully."
}

# Function to configure and start the service
configure_and_start_service() {
    read -p "Enter the port to activate: " PORT
    read -p "Do you want to use HTTP(H) or HTTPS(S)?: " HTTP_OR_HTTPS

    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        read -p "Enter the certificate path (--cert): " CERT_PATH
    fi

    read -p "Enter the proxy status: " RESPONSE
    read -p "Do you want to use only SSH (Y/N)?: " SSH_ONLY

    # Set command options
    OPTIONS="--port $PORT"

    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        OPTIONS="$OPTIONS --https --cert $CERT_PATH"
    else
        OPTIONS="$OPTIONS --http"
    fi

    if [[ $SSH_ONLY == "Y" || $SSH_ONLY == "y" ]]; then
        OPTIONS="$OPTIONS --ssh-only"
    fi

    # Create the service file
    SERVICE_FILE="/etc/systemd/system/proxy-$PORT.service"
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Proxy Active on Port $PORT
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/proxy $OPTIONS --buffer-size $BUFFER_SIZE --workers $WORKERS --response $RESPONSE
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload

    # Start the service and configure automatic start
    systemctl start proxy-$PORT
    systemctl enable proxy-$PORT

    echo "Proxy service on port $PORT has been configured and started automatically."
}

# Function to stop and remove the service
stop_and_remove_service() {
    read -p "Enter the port to stop: " service_number

    # Stop the service
    systemctl stop proxy-$service_number

    # Disable the service
    systemctl disable proxy-$service_number

    # Find and remove the service file
    service_file=$(find /etc/systemd/system -name "proxy-$service_number.service")
    if [ -f "$service_file" ]; then
        rm "$service_file"
        echo "Port removed successfully: $service_file"
    else
        echo "Service file not found for proxy-$service_number service."
    fi

    echo "Proxy-$service_number port stopped and removed."
}

# Function to create a symbolic link to the menu script
create_symbolic_link() {
    SCRIPT_PATH=$(realpath "$0")
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
    LINK_NAME="/usr/local/bin/mainproxy"

    if [[ ! -f "$LINK_NAME" ]]; then
        ln -s "$SCRIPT_PATH" "$LINK_NAME"
        echo "Symbolic link 'mainproxy' created. You can run the menu using 'mainproxy'."
    else
        echo "Symbolic link 'mainproxy' already exists."
    fi
}

# Function to print the header
print_header() {
    echo -e "\n\e[1;94m=======================================\e[0m"
    echo -e "\e[1;94m         TURBONET PROXY MOD MENU       \e[0m"
    echo -e "\e[1;94m=======================================\e[0m"
}

# Management Menu
while true; do
    clear
    print_header
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m1\033[1;31m] \033[1;37m• \033[1;33mInstall TURBONET PROXY MOD \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m2\033[1;31m] \033[1;37m• \033[1;33mStop and Remove Port \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m3\033[1;31m] \033[1;37m• \033[1;33mRestart Proxy \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m4\033[1;31m] \033[1;37m• \033[1;33mView Proxy Status \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m5\033[1;31m] \033[1;37m• \033[1;33mReinstall Proxy \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m6\033[1;31m] \033[1;37m• \033[1;33mExit \033[0m"
    echo -e "\033[1;31m=======================================\e[0m"
    echo ""
    echo -ne "\033[1;31m➤ \033[1;32mChoose desired option\033[1;33m\033[1;31m\033[1;37m: "
    read -p "" choice

    case $choice in
        1 | 01) configure_and_start_service ;;
        2 | 02) stop_and_remove_service ;;
        3 | 03)
            echo "Running services:"
            systemctl list-units --type=service --state=running | grep proxy-
            read -p "Enter the port to restart: " service_number
            systemctl restart proxy-$service_number
            echo "Proxy-$service_number service restarted."
            ;;
        4 | 04)
            systemctl list-units --type=service --state=running | grep proxy-
            ;;
        5 | 05)
            echo "Uninstalling the proxy before reinstalling..."
            uninstall_proxy
            install_proxy
            ;;
        6 | 06)
            echo "Exiting."
            exit
            ;;
        *)
            echo "Invalid option. Choose a valid option."
            ;;
    esac

    read -p "Press Enter to continue..."
done
