#!/bin/sh

# Function to wipe and deploy
wipe_and_deploy() {
    echo "Wiping and deploying the environment..."
    docker compose build --no-cache && docker compose down -v && docker compose up -d
}

# Function to deploy
deploy() {
    echo "Deploying the environment..."
    docker compose build --no-cache && docker compose down && docker compose up -d
}

# Function to restart
restart() {
    echo "Restarting the environment..."
    docker compose down && docker compose up -d
}

# Ask the user for input
read -p "Do you want to [W]ipe and deploy, [D]eploy or [R]estart the environment? (w/d/r): " choice

# Convert choice to lowercase
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

# Check user input and execute corresponding command
case "$choice" in
    w)
        wipe_and_deploy
        ;;
    d)
        deploy
        ;;
    r)
        restart
        ;;
    *)
        echo "Invalid choice. Please choose W for wipe and deploy, D for deploy, or R for restart."
        ;;
esac