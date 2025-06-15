#!/bin/sh

set -e

echo "🚀 Starting MCP HTTP Server..."

# Switch to non-root user if running as root
if [ "$(id -u)" = "0" ]; then
    # Ensure mcpuser exists
    if ! id mcpuser >/dev/null 2>&1; then
        addgroup -g 1001 mcpuser 2>/dev/null || true
        adduser -S mcpuser -u 1001 -G mcpuser 2>/dev/null || true
    fi
    
    exec su-exec mcpuser "$0" "$@"
fi

exec "$@"
