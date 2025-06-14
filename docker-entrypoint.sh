#!/bin/sh

# MCP HTTP Server - Alpine Compatible Docker Permission Fix
# Ensures Docker socket access for code-sandbox-mcp

set -e

echo "=== MCP HTTP Server Startup ==="
echo "Current user: $(whoami) (UID: $(id -u))"

# Must run initial setup as root
if [ "$(id -u)" = "0" ]; then
    echo "🔧 Configuring Docker socket permissions..."
    
    if [ -S "/var/run/docker.sock" ]; then
        # Get Docker socket group ID from host
        DOCKER_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null)
        echo "📋 Host Docker socket GID: $DOCKER_GID"
        
        # Handle different GID scenarios
        if [ "$DOCKER_GID" = "0" ]; then
            echo "📋 Docker socket owned by root - adding mcpuser to root group"
            # Add mcpuser to root group for GID 0
            addgroup mcpuser root 2>/dev/null || true
        else
            echo "🔄 Setting up docker group with GID $DOCKER_GID"
            # Remove existing docker group and recreate with correct GID
            delgroup docker 2>/dev/null || true
            addgroup -g "$DOCKER_GID" docker
            addgroup mcpuser docker
        fi
        
        # Ensure mcpuser exists
        if ! id mcpuser >/dev/null 2>&1; then
            echo "➕ Creating mcpuser"
            adduser -S mcpuser -u 1001
        fi
        
        # Test Docker access as mcpuser
        echo "🔍 Testing Docker access..."
        if su-exec mcpuser docker version >/dev/null 2>&1; then
            echo "✅ Docker access confirmed"
        else
            echo "⚠️  Docker access test failed, but continuing..."
        fi
        
        echo "🔄 Switching to mcpuser"
        exec su-exec mcpuser "$0" "$@"
    else
        echo "❌ Docker socket not found at /var/run/docker.sock"
        exit 1
    fi
fi

echo "🚀 Starting MCP HTTP Server as $(whoami)..."
exec "$@"
