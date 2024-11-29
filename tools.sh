#!/bin/bash

# Set strict error handling
set -euo pipefail

# Detect the operating system
OS="$(uname)"

# Function to determine if sudo is needed
needs_sudo() {
    if [ "$OS" = "Linux" ]; then
        echo "sudo"
    else
        echo ""
    fi
}

# Function to clear the screen and show the header
show_header() {
    clear
    echo "==================================="
    echo "WillowCMS Command Runner"
    echo "==================================="
    echo
}

# Function to display the menu
show_menu() {
    echo "Available Commands:"
    echo
    echo "Data Management:"
    echo "  1) Import Default Data"
    echo "  2) Export Default Data"
    echo "  3) Dump MySQL Database"
    echo
    echo "Internationalization:"
    echo "  4) Extract i18n Messages"
    echo "  5) Load Default i18n"
    echo "  6) Translate i18n"
    echo "  7) Generate PO Files"
    echo
    echo "System:"
    echo "  8) Clear Cache"
    echo "  9) Interactive shell on Willow CMS"
    echo "  0) Exit"
    echo
}

# Function to pause and wait for user input
pause() {
    echo
    read -p "Press [Enter] key to continue..." fackEnterKey
}

# Function to execute commands
execute_command() {
    case $1 in
        1)
            echo "Running Default Data Import..."
            $(needs_sudo) docker compose exec willowcms bin/cake default_data_import
            ;;
        2)
            echo "Running Default Data Export..."
            $(needs_sudo) docker compose exec willowcms bin/cake default_data_export
            ;;
        3)
            echo "Dumping MySQL Database..."
            local timestamp=$(date '+%Y%m%d_%H%M%S')
            local backup_dir="database/backups"
            local backup_file="willow_backup_${timestamp}.sql"
            
            # Create backup directory if it doesn't exist
            mkdir -p "${backup_dir}"
            
            # Backup using the container's environment variables
            $(needs_sudo) docker compose exec mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" "$DB_DATABASE"' > "${backup_dir}/${backup_file}"
            
            if [ $? -eq 0 ]; then
                echo "Database backup completed successfully!"
                echo "Backup saved to: ${backup_dir}/${backup_file}"
            else
                echo "Error: Database backup failed!"
            fi
            ;;
        4)
            echo "Extracting i18n Messages..."
            $(needs_sudo) docker compose exec willowcms bin/cake i18n extract \
                --paths /var/www/html/src,/var/www/html/plugins,/var/www/html/templates
            ;;
        5)
            echo "Loading Default i18n..."
            $(needs_sudo) docker compose exec willowcms bin/cake load_default18n
            ;;
        6)
            echo "Running i18n Translation..."
            $(needs_sudo) docker compose exec willowcms bin/cake translate_i18n
            ;;
        7)
            echo "Generating PO Files..."
            $(needs_sudo) docker compose exec willowcms bin/cake generate_po_files
            ;;
        8)
            echo "Clearing Cache..."
            $(needs_sudo) docker compose exec willowcms bin/cake cache clear_all
            ;;
        9)
            echo "Opening an interactive shell to Willow CMS..."
            $(needs_sudo) docker compose exec -it willowcms /bin/sh
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Error: Invalid option"
            ;;
    esac
}

# Function to check if Docker is running
check_docker() {
    if ! $(needs_sudo) docker compose ps --services --filter "status=running" | grep -q "willowcms"; then
        echo "Error: WillowCMS Docker container is not running"
        echo "Please start the containers first using ./setup_dev_env.sh"
        exit 1
    fi
}

# Main program loop
main() {
    local choice

    # Check if Docker is running first
    check_docker

    while true; do
        show_header
        show_menu
        read -p "Enter your choice [0-9]: " choice
        
        if [[ ! $choice =~ ^[0-9]$ ]]; then
            echo "Error: Please enter a number between 0 and 9"
            pause
            continue
        fi

        echo
        execute_command "$choice"
        
        if [ "$choice" != "0" ]; then
            pause
        fi
    done
}

# Start the program
main