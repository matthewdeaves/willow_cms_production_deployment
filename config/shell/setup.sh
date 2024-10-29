#!/bin/sh
set -e

# If this is the first run, update teh .env file
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    # Replace variables in .env file with environment variables
    for var in $(printenv | grep -E '^APP_|^DB_|^EMAIL_|^REDIS_|^CACHE_|^ARTICLES_|^QUEUE_|^SECURITY_'); do
    sed -i "s/^export ${var}=.*$/export ${var}=\"${!var}\"/" config/.env
    done
fi
# Define the flag file
FIRST_RUN_FLAG="/var/lib/willow/first_run_completed"

# Wait for the database to be ready
/usr/local/bin/wait-for-it.sh mysql:3306 -t 60

# Run migrations (always safe since database records which have run)
bin/cake migrations migrate

# If this is the first run, setup a default user, import default data
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    echo "First time container startup detected. Running initial setup..."

    # Create default admin user (only if it doesn't exist)
    bin/cake create_user -u admin -p password -e admin@test.com -a 1 || true
    bin/cake create_user -u "$WILLOW_ADMIN_USERNAME" -p "$WILLOW_ADMIN_PASSWORD" -e "$WILLOWADMIN_EMAIL" -a 1 || true

    # Import default data
    bin/cake default_data_import --all

    # Create the flag file to indicate first run is completed
    mkdir -p /var/lib/willow && chown -R nobody:nobody /var/lib/willow
    touch "$FIRST_RUN_FLAG"

    echo "Initial setup completed."
else
    echo "Subsequent container startup detected. Skipping initial setup."
fi

# Clear cache (this will run every time)
bin/cake cache clear_all

# Start supervisord
exec "$@"