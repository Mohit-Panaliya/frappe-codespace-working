#!/bin/bash

set -e

# Check if Frappe Bench already exists
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# Remove Git files if any
rm -rf /workspaces/frappe_codespace/.git

# Load NVM (Ensure correct path)
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18

# Add nvm use command to .bashrc
echo "nvm use 18" >> ~/.bashrc  

# Move to the workspace directory
cd /workspaces

# Initialize the Frappe Bench with version-15
bench init \
  --frappe-branch version-15 \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

# Change directory to the new bench
cd frappe-bench

# Configure Redis and MariaDB hosts
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove Redis from the Procfile
sed -i '/redis/d' ./Procfile

# Create a new site
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --admin-password admin \
  --no-mariadb-socket

# Set developer mode
bench --site dev.localhost set-config developer_mode 1

# Clear the cache
bench --site dev.localhost clear-cache

# Use the created site
bench use dev.localhost

# Log success message
echo "Frappe Bench setup is complete and running."
