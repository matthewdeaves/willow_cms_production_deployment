#!/bin/sh
set -e

# Define the flag file
FIRST_RUN_FLAG="/var/lib/willow/first_run_completed"

# Check if DB_HOST and DB_PORT are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ]; then
    echo "Error: DB_HOST and DB_PORT environment variables are not set."
    exit 1
fi

# Create redis.conf file with provided Redis credentials...
echo "requirepass ${REDIS_SERVER_PASSWORD}" >> /etc/redis.conf && \
echo "bind 127.0.0.1" >> /etc/redis.conf && \
echo "user ${REDIS_SERVER_USERNAME} on >${REDIS_SERVER_PASSWORD} ~* +@all" >> /etc/redis.conf

# Wait for the database to be ready
/usr/local/bin/wait-for-it.sh $DB_HOST:$DB_PORT -t 60

# Run migrations (always safe since database records which have run)
bin/cake migrations migrate

# If this is the first run, setup a default user, import default data
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    echo "First time container startup detected. Running initial setup..."

    # Create default admin user (only if it doesn't exist)
    bin/cake create_user -u admin -p password -e admin@test.com -a 1 || true
    bin/cake create_user -u "$WILLOW_ADMIN_USERNAME" -p "$WILLOW_ADMIN_PASSWORD" -e "$WILLOW_ADMIN_EMAIL" -a 1 || true

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