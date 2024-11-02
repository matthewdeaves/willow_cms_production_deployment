#!/bin/bash

# Check if DB_HOST and DB_PORT are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ]; then
    echo "Error: DB_HOST and DB_PORT environment variables are not set."
    exit 1
fi

# Wait for the database to be ready
/usr/local/bin/wait-for-it.sh $DB_HOST:$DB_PORT -t 20

# Check if database has been setup (has a settings table) - database may empty
bin/cake check_table_exists settings
tableExists=$?

if [ "$tableExists" -eq 1 ]; then
    echo "Running initial setup..."

    # Run migrations (always safe since database records which have run)
    bin/cake migrations migrate
    
    # Create default admin user (only if it doesn't exist)
    bin/cake create_user -u "$WILLOW_ADMIN_USERNAME" -p "$WILLOW_ADMIN_PASSWORD" -e "$WILLOW_ADMIN_EMAIL" -a 1 || true

    # Import default data
    bin/cake default_data_import --all

    echo "Initial setup completed."
fi

# Run migrations (always safe since database records which have run)
bin/cake migrations migrate

# Clear cache
bin/cake cache clear_all

# Start supervisord
exec "$@"
