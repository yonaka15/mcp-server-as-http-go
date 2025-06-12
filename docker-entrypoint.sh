#!/bin/sh

# Docker Group ID Dynamic Mapping Script
# This script maps the host Docker group ID to the container

# Get Docker socket group ID from host
DOCKER_GID=$(stat -c %g /var/run/docker.sock 2>/dev/null || echo "999")

echo "Host Docker group ID: $DOCKER_GID"

# Create docker group with host GID if it doesn't exist
if ! getent group docker > /dev/null 2>&1; then
    echo "Creating docker group with GID: $DOCKER_GID"
    addgroup -g $DOCKER_GID docker
fi

# Add mcpuser to docker group
echo "Adding mcpuser to docker group"
adduser mcpuser docker 2>/dev/null || true

# Switch to mcpuser and execute the main application
echo "Starting MCP HTTP Server as mcpuser..."
exec su-exec mcpuser "$@"
