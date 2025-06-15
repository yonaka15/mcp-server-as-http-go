#!/bin/sh

# MCP HTTP Server - GitHub MCP Server Lightweight Entrypoint
# Minimal setup for GitHub MCP Server (no Docker required)

set -e

echo "=== GitHub MCP HTTP Server Startup ==="
echo "Current user: $(whoami) (UID: $(id -u))"

# Must run initial setup as root
if [ "$(id -u)" = "0" ]; then
    echo "ℹ️  Setting up user permissions..."
    
    # Ensure mcpuser exists
    if ! id mcpuser >/dev/null 2>&1; then
        echo "➕ Creating mcpuser"
        addgroup -g 1001 mcpuser 2>/dev/null || true
        adduser -S mcpuser -u 1001 -G mcpuser 2>/dev/null || true
    fi
    
    echo "🔄 Switching to mcpuser"
    exec su-exec mcpuser "$0" "$@"
fi

# Running as mcpuser
echo "🚀 Starting GitHub MCP HTTP Server as $(whoami)..."
echo "🐙 GitHub MCP Server Configuration:"
echo "   - Toolsets: ${GITHUB_TOOLSETS:-all}"
echo "   - Read Only: ${GITHUB_READ_ONLY:-false}"
echo "   - Dynamic Toolsets: ${GITHUB_DYNAMIC_TOOLSETS:-false}"
if [ -n "${GITHUB_HOST}" ]; then
    echo "   - GitHub Host: ${GITHUB_HOST}"
fi

exec "$@"
