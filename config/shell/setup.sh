#!/bin/sh
set -e

# Define the flag file
FIRST_RUN_FLAG="/var/lib/willow/first_run_completed"

# Wait for the database to be ready
/usr/local/bin/wait-for-it.sh mysql:3306 -t 60

# Check if this is the first run
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    echo "First time container startup detected. Running initial setup..."

    # Run migrations
    bin/cake migrations migrate

    # Create default admin user (only if it doesn't exist)
    bin/cake create_user -u admin -p password -e admin@test.com -a 1 || true

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