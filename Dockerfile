# MCP HTTP Server - Code Sandbox (Lightweight)
# Minimal setup with binary runtime only

# Stage 1: Rust builder for HTTP core
FROM --platform=${BUILDPLATFORM} rust:1.85-alpine AS rust-builder

# Install build dependencies
RUN apk add --no-cache \
  musl-dev \
  openssl-dev \
  openssl-libs-static \
  git \
  pkgconfig

# Build arguments
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

# Static linking configuration
ENV RUSTFLAGS="-C target-feature=+crt-static" \
  PKG_CONFIG_ALL_STATIC=1 \
  PKG_CONFIG_ALL_DYNAMIC=0

WORKDIR /build

# Clone the latest version from GitHub
RUN git clone https://github.com/yonaka15/mcp-server-as-http-core.git .

# For development with local source, use:
# COPY mcp-server-as-http-core .

# Build optimized binary
RUN RUST_TARGET=$(cat /target.txt) && \
  cargo build \
  --release \
  --target ${RUST_TARGET} \
  --config 'profile.release.lto = true' \
  --config 'profile.release.codegen-units = 1' \
  --config 'profile.release.panic = "abort"' \
  --config 'profile.release.strip = true' && \
  cp target/${RUST_TARGET}/release/mcp-server-as-http-core /mcp-http-server

# Stage 2: Download code-sandbox-mcp binary
FROM --platform=${BUILDPLATFORM} alpine:latest AS binary-downloader

ARG TARGETPLATFORM

# Install minimal tools
RUN apk add --no-cache curl jq

# Determine download architecture
RUN case "${TARGETPLATFORM}" in \
  "linux/amd64") echo "linux-amd64" > /arch.txt ;; \
  "linux/arm64") echo "linux-arm64" > /arch.txt ;; \
  *) echo "Unsupported: ${TARGETPLATFORM}" && exit 1 ;; \
  esac

# Download latest binary
RUN ARCH=$(cat /arch.txt) && \
  URL=$(curl -s https://api.github.com/repos/Automata-Labs-team/code-sandbox-mcp/releases/latest | \
  jq -r ".assets[] | select(.name | contains(\"code-sandbox-mcp-${ARCH}\")) | .browser_download_url") && \
  echo "Downloading: $URL" && \
  curl -L "$URL" -o /code-sandbox-mcp && \
  chmod +x /code-sandbox-mcp

# Stage 3: Minimal runtime
FROM alpine:latest

# Install minimal runtime dependencies
RUN apk add --no-cache \
  curl \
  docker-cli \
  ca-certificates \
  nodejs \
  npm \
  && rm -rf /var/cache/apk/* \
  && addgroup -g 1001 -S mcpuser \
  && adduser -S mcpuser -u 1001 -G mcpuser \
  && addgroup docker \
  && adduser mcpuser docker

WORKDIR /app

# Copy binaries
COPY --from=rust-builder /mcp-http-server ./mcp-http-server
COPY --from=binary-downloader /code-sandbox-mcp ./code-sandbox-mcp

# Copy minimal configuration
COPY mcp-server-as-go/mcp_servers.config.json ./

# Setup permissions
RUN chmod +x ./mcp-http-server ./code-sandbox-mcp && \
  mkdir -p /tmp/mcp-servers && \
  chown -R mcpuser:mcpuser /app /tmp/mcp-servers

USER mcpuser

# Minimal environment
#ENV MCP_CONFIG_FILE=mcp_servers.config.json \
#    MCP_SERVER_NAME=code-sandbox \
#    MCP_RUNTIME_TYPE=node \
#    PORT=3000 \
#    DOCKER_HOST=unix:///var/run/docker.sock \
#    RUST_LOG=info

# Port will be dynamically set by docker-compose
# EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

CMD ["./mcp-http-server"]
