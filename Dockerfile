# MCP HTTP Server - Universal MCP Server Runner
# Single container with Rust HTTP Core + Go environment for various MCP servers

# Stage 1: Rust builder for HTTP core
FROM --platform=${BUILDPLATFORM} rust:alpine AS rust-builder

# Install build dependencies for Rust compilation
RUN apk add --no-cache \
  musl-dev \
  openssl-dev \
  openssl-libs-static \
  git \
  pkgconfig

# Build arguments for cross-compilation
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Set target for cross-compilation
RUN case "${TARGETPLATFORM}" in \
  "linux/amd64") \
  echo "x86_64-unknown-linux-musl" > /target.txt && \
  rustup target add x86_64-unknown-linux-musl \
  ;; \
  "linux/arm64") \
  echo "aarch64-unknown-linux-musl" > /target.txt && \
  rustup target add aarch64-unknown-linux-musl \
  ;; \
  *) \
  echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 \
  ;; \
  esac

# Static linking configuration for minimal binary
ENV RUSTFLAGS="-C target-feature=+crt-static" \
  PKG_CONFIG_ALL_STATIC=1 \
  PKG_CONFIG_ALL_DYNAMIC=0

WORKDIR /build

# Clone the latest HTTP core from GitHub
RUN git clone --branch v0.1.1 https://github.com/yonaka15/mcp-server-as-http-core.git .

# Build optimized Rust binary
RUN RUST_TARGET=$(cat /target.txt) && \
  cargo build \
  --release \
  --target ${RUST_TARGET} \
  --config 'profile.release.lto = true' \
  --config 'profile.release.codegen-units = 1' \
  --config 'profile.release.panic = "abort"' \
  --config 'profile.release.strip = true' && \
  cp target/${RUST_TARGET}/release/mcp-server-as-http-core /mcp-http-server

# Stage 2: Runtime with Go environment
# Using golang:alpine for optimized Go toolchain (latest version)
FROM golang:alpine

# Install runtime dependencies
RUN apk add --no-cache \
  curl \
  ca-certificates \
  git \
  su-exec

# Conditionally install Docker CLI for code-sandbox MCP servers
# This can be enabled by setting ENABLE_DOCKER=true during build
ARG ENABLE_DOCKER=false
RUN if [ "$ENABLE_DOCKER" = "true" ]; then \
  apk add --no-cache docker-cli && \
  addgroup docker; \
  fi

# Create mcpuser and setup directories
RUN addgroup -g 1001 mcpuser && \
  adduser -S mcpuser -u 1001 -G mcpuser && \
  mkdir -p /tmp/mcp-servers && \
  chown -R mcpuser:mcpuser /tmp/mcp-servers

# Add mcpuser to docker group if Docker is enabled
RUN if [ "$ENABLE_DOCKER" = "true" ]; then \
  addgroup mcpuser docker; \
  fi

WORKDIR /app

# Copy the Rust HTTP server binary
COPY --from=rust-builder /mcp-http-server ./mcp-http-server

# Copy configuration files
COPY *.config.json ./

# Copy entrypoint script
COPY docker-entrypoint.sh ./docker-entrypoint.sh

# Setup permissions
RUN chmod +x ./mcp-http-server ./docker-entrypoint.sh && \
  chown -R mcpuser:mcpuser /app

# Expose port (dynamically configured via PORT environment variable)
EXPOSE ${PORT:-3000}

# Health check for container monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

# Start with entrypoint for flexible initialization
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["./mcp-http-server"]
