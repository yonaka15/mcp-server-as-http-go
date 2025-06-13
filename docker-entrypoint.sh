#!/bin/sh

# Docker Group ID Dynamic Mapping Script
# This script maps the host Docker group ID to the container

# Exit on error, but handle specific cases gracefully
set -e

# Trap to show error context
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?"' ERR

echo "=== Docker Permission Setup ==="

# Wait for Docker daemon to be ready when using DinD
if [ "$DOCKER_HOST" = "tcp://docker-daemon:2376" ]; then
    echo "Waiting for Docker-in-Docker daemon to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker version >/dev/null 2>&1; then
            echo "Docker daemon is ready!"
            break
        fi
        echo "Waiting for Docker daemon... ($timeout seconds left)"
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "ERROR: Docker daemon is not ready after 60 seconds"
        echo "DOCKER_HOST: $DOCKER_HOST"
        echo "Attempting to connect to Docker daemon..."
        docker version || echo "Failed to connect to Docker daemon"
        exit 1
    fi
fi

# Get Docker socket group ID from host (for non-DinD setups)
DOCKER_GID=$(stat -c %g /var/run/docker.sock 2>/dev/null || echo "999")

echo "Host Docker group ID: $DOCKER_GID"

# Create docker group with host GID if it doesn't exist
if ! getent group docker > /dev/null 2>&1; then
    echo "Creating docker group with GID: $DOCKER_GID"
    if ! addgroup -g $DOCKER_GID docker 2>/dev/null; then
        echo "⚠️  GID $DOCKER_GID already in use, using existing docker group"
        # Try to create docker group with system-assigned GID
        if ! addgroup docker 2>/dev/null; then
            echo "ℹ️  Docker group already exists, continuing..."
        fi
    fi
else
    echo "ℹ️  Docker group already exists"
fi

# Add mcpuser to docker group
echo "Adding mcpuser to docker group"
if ! adduser mcpuser docker 2>/dev/null; then
    echo "⚠️  Failed to add mcpuser to docker group, but continuing..."
fi

# Verify group membership
if groups mcpuser | grep -q docker; then
    echo "✅ mcpuser is now in docker group"
else
    echo "⚠️  mcpuser is not in docker group, permissions may be limited"
fi

# Verify Docker access
echo "Verifying Docker access..."
if su-exec mcpuser docker version >/dev/null 2>&1; then
    echo "✅ Docker access verified successfully"
else
    echo "⚠️  Docker access verification failed, but continuing..."
    echo "Docker host: $DOCKER_HOST"
fi

# Pre-pull common images to avoid permission issues during runtime
echo "Pre-pulling common Docker images..."
common_images="python:3.12-slim-bookworm node:18"
for image in $common_images; do
    echo "Pulling $image..."
    if timeout 120 su-exec mcpuser docker pull "$image" >/dev/null 2>&1; then
        echo "✅ Successfully pulled $image"
    else
        echo "⚠️  Failed to pull $image (will be pulled on-demand)"
    fi
done
echo "ℹ️  Image pre-pulling completed"

echo "=== Starting MCP HTTP Server ==="
echo "Starting MCP HTTP Server as mcpuser..."
exec su-exec mcpuser "$@"
