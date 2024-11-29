#!/bin/sh

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
    echo "  4) Load Database from Backup"
    echo
    echo "Internationalization:"
    echo "  5) Extract i18n Messages"
    echo "  6) Load Default i18n"
    echo "  7) Translate i18n"
    echo "  8) Generate PO Files"
    echo
    echo "System:"
    echo "  9) Clear Cache"
    echo "  10) Interactive shell on Willow CMS"
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
            local backup_dir="/willow/backups"
            local backup_file="backup_${timestamp}.sql"
            
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
            echo "Loading Database from Backup..."
            local backup_dir="/willow/backups"
            
            # Check if backup directory exists and contains SQL files
            if [ ! -d "${backup_dir}" ] || [ -z "$(ls -A ${backup_dir}/*.sql 2>/dev/null)" ]; then
                echo "No backup files found in ${backup_dir}"
                return 1
            fi
            
            # List backups with numbers
            echo "Available backups:"
            echo
            
            # Create numbered list of backups
            i=1
            for file in "${backup_dir}"/*.sql; do
                echo "$i) $(basename "$file")"
                i=$((i + 1))
            done
            echo
            
            # Get user selection
            read -p "Enter the number of the backup to restore (or 0 to cancel): " selection
            
            # Validate input is a number
            if ! echo "$selection" | grep -q '^[0-9]\+$'; then
                echo "Invalid selection: not a number"
                return 1
            fi
            
            # Handle cancellation
            if [ "$selection" = "0" ]; then
                echo "Operation cancelled."
                return 0
            fi
            
            # Find selected file
            i=1
            backup_file=""
            for file in "${backup_dir}"/*.sql; do
                if [ "$i" = "$selection" ]; then
                    backup_file="$file"
                    break
                fi
                i=$((i + 1))
            done
            
            # Validate selection
            if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
                echo "Invalid selection: backup file not found"
                return 1
            fi
            
            echo "Restoring from $backup_file..."
            
            # Get database name from environment
            DB_NAME=$($(needs_sudo) docker compose exec mysql sh -c 'echo "$DB_DATABASE"')
            
            echo "This will drop the existing database '$DB_NAME' and restore from backup."
            echo "Are you sure you want to continue? (y/n)"
            read -r confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                # Drop and recreate database
                echo "Dropping and recreating database..."
                $(needs_sudo) docker compose exec mysql sh -c '
                    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
                        DROP DATABASE IF EXISTS $DB_DATABASE;
                        CREATE DATABASE $DB_DATABASE;
                        USE $DB_DATABASE;
                    "
                '
                
                # Restore the backup
                echo "Restoring backup..."
                $(needs_sudo) docker compose exec -T mysql sh -c '
                    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$DB_DATABASE"
                ' < "$backup_file"
                
                if [ $? -eq 0 ]; then
                    echo "Database restored successfully from $backup_file!"
                    
                    # Clear CakePHP cache after restore
                    echo "Clearing CakePHP cache..."
                    $(needs_sudo) docker compose exec willowcms bin/cake cache clear_all
                else
                    echo "Error: Database restore failed!"
                fi
            else
                echo "Database restore cancelled."
            fi
            ;;

        5)
            echo "Extracting i18n Messages..."
            $(needs_sudo) docker compose exec willowcms bin/cake i18n extract \
                --paths /var/www/html/src,/var/www/html/plugins,/var/www/html/templates
            ;;
        6)
            echo "Loading Default i18n..."
            $(needs_sudo) docker compose exec willowcms bin/cake load_default18n
            ;;
        7)
            echo "Running i18n Translation..."
            $(needs_sudo) docker compose exec willowcms bin/cake translate_i18n
            ;;
        8)
            echo "Generating PO Files..."
            $(needs_sudo) docker compose exec willowcms bin/cake generate_po_files
            ;;
        9)
            echo "Clearing Cache..."
            $(needs_sudo) docker compose exec willowcms bin/cake cache clear_all
            ;;
        10)
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
        read -p "Enter your choice [0-10]: " choice
        
        if [[ ! $choice =~ ^[0-9]+$ ]] || [ "$choice" -gt 10 ]; then
            echo "Error: Please enter a number between 0 and 10"
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