#!/bin/bash

# Install nginx if not already installed
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Copy nginx config
sudo cp /workspace/claude_code/nginx.conf /etc/nginx/nginx.conf

# Stop any existing nginx
sudo nginx -s stop 2>/dev/null || true

# Start nginx
echo "Starting nginx proxy on localhost:3000..."
sudo nginx

# Keep the container running
tail -f /dev/null