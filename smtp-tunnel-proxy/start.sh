#!/bin/bash

# Configuration directory
CONFIG_DIR="/etc/smtp-tunnel"
if [ ! -d "$CONFIG_DIR" ]; then
    CONFIG_DIR="./config"
    mkdir -p "$CONFIG_DIR"
fi

# Use environment variable for domain name, fallback to a default if not set
DOMAIN_NAME=${DOMAIN_NAME:-"localhost"}
PORT=${PORT:-587}

echo "Starting SMTP Tunnel Proxy with Domain: $DOMAIN_NAME on Port: $PORT"

# Generate config.yaml if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    echo "Generating config.yaml..."
    cat > "$CONFIG_DIR/config.yaml" << EOF
server:
  host: "0.0.0.0"
  port: $PORT
  hostname: "$DOMAIN_NAME"
  cert_file: "$CONFIG_DIR/server.crt"
  key_file: "$CONFIG_DIR/server.key"
  users_file: "$CONFIG_DIR/users.yaml"
  log_users: true
EOF
fi

# Generate users.yaml if it doesn't exist
if [ ! -f "$CONFIG_DIR/users.yaml" ]; then
    echo "Generating users.yaml..."
    echo "users: {}" > "$CONFIG_DIR/users.yaml"
fi

# Generate certificates if they don't exist
if [ ! -f "$CONFIG_DIR/server.crt" ]; then
    echo "Generating certificates..."
    python3 generate_certs.py --hostname "$DOMAIN_NAME" --output-dir "$CONFIG_DIR"
fi

# Start the server
exec python3 server.py -c "$CONFIG_DIR/config.yaml"
