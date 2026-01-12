#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the workspace directory explicitly
WORKSPACE_DIR="/workspaces/frappe_codespace"
BENCH_NAME="frappe-bench"

# 1. Dynamic NVM Loading
# GitHub Codespaces usually load NVM in the environment, but if not, we find it.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "/usr/local/share/nvm/nvm.sh" ] && \. "/usr/local/share/nvm/nvm.sh" # Standard Codespace path

# Verify NVM is loaded
if ! command -v nvm &> /dev/null; then
    echo "Error: nvm could not be found. Please ensure Node.js is installed."
    exit 1
fi

# Set Node Version
nvm install 18
nvm alias default 18
nvm use 18

# 2. Check if Bench already exists
if [[ -d "$WORKSPACE_DIR/$BENCH_NAME/apps/frappe" ]]; then
    echo "Bench already exists at $WORKSPACE_DIR/$BENCH_NAME, skipping init..."
    # Still need to start services or ensure config is correct, skipping to end or exiting
    exit 0
fi

# 3. Clean up Git (Use with caution)
# Only remove .git if you strictly intend to detach from your current repo
if [ -d "$WORKSPACE_DIR/.git" ]; then
    echo "Removing existing .git directory to start fresh..."
    rm -rf "$WORKSPACE_DIR/.git"
fi

# Move to workspace
# cd "$WORKSPACE_DIR"

# 4. Initialize Frappe Bench
# Added --verbose to help debug if it fails
echo "Initializing Frappe Bench (Version 15)..."
bench init \
  --frappe-branch version-15 \
  --skip-redis-config-generation \
  --verbose \
  "$BENCH_NAME"

# Change directory to the new bench
cd "$BENCH_NAME"

# 5. Configure External Services (Docker Containers)
# These hostnames (mariadb, redis-cache) must match your docker-compose service names
echo "Configuring Bench for Docker services..."
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove Redis from Procfile (since we use external containers)
if [ -f "./Procfile" ]; then
    sed -i '/redis/d' ./Procfile
fi

# 6. Create a New Site
# --no-mariadb-socket is CRITICAL when connecting to a DB container from the app container
echo "Creating new site dev.localhost..."
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --admin-password admin \
  --no-mariadb-socket \
  --db-host mariadb \
  --force

# 7. Developer Settings
echo "Setting developer mode..."
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

# 8. Start the Bench (Optional)
# In Codespaces, you usually run 'bench start' manually so you can see the logs
echo "------------------------------------------------"
echo "Setup Complete! Run the following command to start:"
echo "cd $WORKSPACE_DIR/$BENCH_NAME && bench start"
echo "------------------------------------------------"
