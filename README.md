# MCP HTTP Server - Code Sandbox (Go)

A **lightweight** HTTP server that provides RESTful API access to [`code-sandbox-mcp`](https://github.com/Automata-Labs-team/code-sandbox-mcp) (Go) using [`mcp-server-as-http-core`](https://github.com/yonaka15/mcp-server-as-http-core) (Rust).

> **⚡ Lightweight**: Minimal Alpine-based image with Go binary execution  
> **🌐 HTTP API**: Transform MCP tools into accessible HTTP endpoints  
> **🔧 Simple**: Docker + Rust HTTP Core + Go MCP Binary  
> **🚀 Ultra-Fast Startup**: Direct binary execution with no overhead

## 🏗️ Architecture

```
mcp-server-as-go/
├── Dockerfile                  # HTTP Core + Go Binary
├── docker-compose.yml          # Simple configuration
├── mcp_servers.config.json     # Go binary configuration
├── .env.example                # Minimal environment
└── README.md                   # This file
```

**Components:**
- **HTTP Core**: Rust binary for HTTP/JSON-RPC bridge (~10MB)
- **Code Sandbox**: Pre-built Go binary for secure execution (~15MB)  
- **Runtime**: Alpine Linux with Docker CLI + minimal Node.js (~85MB total)
- **Bridge**: **Direct process execution** - language agnostic protocol bridge

**v2.0+ Simplified Flow:**
```
HTTP Request (JSON-RPC) → MCP HTTP Server → Direct Process Spawn → code-sandbox-mcp → JSON-RPC Response → HTTP Response
```

## 🚀 Quick Start

```bash
# Clone and start
git clone https://github.com/yonaka15/mcp-server-as-go.git
cd mcp-server-as-go

# Start services (automatic Docker permission handling)
docker-compose up -d

# Test health
curl -f http://localhost:3000/health

# List available tools
curl -X POST http://localhost:3000/api/v1 \
  -H "Content-Type: application/json" \
  -d '{"command": "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/list\", \"params\": {}}"}'
```

## 🛠️ HTTP API

### List Available Tools
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Content-Type: application/json" \
  -d '{"command": "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/list\", \"params\": {}}"}'
```

### Initialize Sandbox
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 1,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"sandbox_initialize\",
        \"arguments\": {\"image\": \"python:3.12-slim\"}
      }
    }"
  }'
```

### Execute Code
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 2,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"sandbox_exec\",
        \"arguments\": {
          \"container_id\": \"your-container-id\",
          \"commands\": [\"python -c \\\"print('Hello from Go MCP!')\\\"\"]
        }
      }
    }"
  }'
```

### Write File to Sandbox
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 3,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"write_file_sandbox\",
        \"arguments\": {
          \"container_id\": \"your-container-id\",
          \"file_name\": \"hello.py\",
          \"file_contents\": \"print('Hello from sandbox file!')\"
        }
      }
    }"
  }'
```

## ⚙️ Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_SERVER_NAME` | `code-sandbox` | MCP server name from config |
| `MCP_CONFIG_FILE` | `mcp_servers.config.json` | MCP server configuration file |
| `PORT` | `3000` | HTTP server port |
| `DISABLE_AUTH` | `true` | Disable authentication for simplicity |
| `RUST_LOG` | `info` | Log level (error, warn, info, debug, trace) |
| `HTTP_API_KEY` | - | Optional Bearer token for authentication |
| `DOCKER_HOST` | `unix:///var/run/docker.sock` | Docker daemon socket |

**Note**: Docker permissions are handled automatically in the container!

## 🔧 Available Tools (Go MCP)

- **`sandbox_initialize`**: Create isolated Docker container for code execution
- **`sandbox_exec`**: Execute shell commands in container
- **`copy_project`**: Copy local directories to container filesystem
- **`write_file_sandbox`**: Write files directly to container
- **`copy_file`**: Copy single files to container
- **`copy_file_from_sandbox`**: Copy files from container to local
- **`sandbox_stop`**: Stop and remove container with cleanup

## 🐳 Docker Features

- **Multi-language Support**: Python, Go, Node.js, and custom Docker images
- **Container Isolation**: Each sandbox runs in isolated Docker container
- **Resource Management**: Automatic cleanup and resource limits
- **File Operations**: Bidirectional file transfer between host and containers
- **Real-time Logging**: Container logs accessible via HTTP API

## 📦 Image Size

- **Total**: ~85MB (Alpine + Rust HTTP Core + Go MCP Binary + minimal Node.js)
- **Memory**: 128-256MB runtime usage
- **CPU**: 0.1-0.3 cores typical usage

## 🚀 Production

```bash
# With authentication
HTTP_API_KEY=your-secret-key DISABLE_AUTH=false docker-compose up -d

# Health monitoring
curl -f http://localhost:3000/health

# View logs
docker-compose logs -f mcp-http-server

# Resource monitoring
docker stats mcp-http-server
```

## 🔒 Security

- **Container Isolation**: Code executes in isolated Docker containers
- **Non-root Execution**: All processes run as non-root user
- **Docker Socket**: Read-only mount for container management
- **Optional Authentication**: Bearer token support
- **Resource Limits**: CPU and memory constraints
- **Network Isolation**: Containers have limited network access

## 🎯 Use Cases

- **AI Code Execution**: Let AI models safely run and test code
- **Educational Platforms**: Secure code execution for learning environments
- **CI/CD Integration**: Automated code testing in isolated environments
- **API Testing**: HTTP endpoints for code execution workflows
- **Development Tools**: Remote code execution capabilities

## 🔍 API Response Examples

### Tools List Response
```json
{
  "result": {
    "tools": [
      {
        "name": "sandbox_initialize",
        "description": "Initialize a new compute environment for code execution"
      },
      {
        "name": "sandbox_exec", 
        "description": "Execute commands in the sandboxed environment"
      }
    ]
  }
}
```

### Sandbox Initialize Response
```json
{
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Container initialized successfully with ID: abc123def456"
      }
    ]
  }
}
```

## 📋 Change Log

### v2.0.0 - 2025-06-13 - **Major Architecture Simplification**

**🎯 BREAKING CHANGE: Removed Runtime Type Dependency**

Previously, the MCP HTTP Core required specifying a runtime type (`node`, `python`, `go`, `binary`) which was architecturally incorrect for a protocol bridge.

#### What Changed:
- **Removed `MCP_RUNTIME_TYPE` environment variable** - No longer needed
- **Eliminated runtime abstraction layer** - Direct process execution
- **Deleted `src/runtime.rs` file** - 370+ lines of unnecessary code removed
- **Simplified configuration** - Only server name and command needed
- **Reduced codebase by 60%+** - Removed entire runtime module
- **True protocol neutrality** - Works with any MCP server regardless of language

#### Why This Change:
```diff
- HTTP Request → Runtime Selection → Environment Setup → Process Spawn → MCP Server
+ HTTP Request → Direct Process Spawn → MCP Server
```

**Before (v1.x):**
```bash
# Required runtime specification
MCP_RUNTIME_TYPE=node  # or python, go, binary
MCP_SERVER_NAME=code-sandbox
```

**After (v2.0+):**
```bash
# Runtime type completely removed
MCP_SERVER_NAME=code-sandbox
```

#### Technical Rationale:
1. **MCP is a Protocol**: Like LSP (Language Server Protocol), MCP uses stdin/stdout communication and doesn't need runtime-specific handling
2. **HTTP Bridge Role**: The core server's job is to bridge HTTP ↔ JSON-RPC, not manage language environments
3. **Simplified Maintenance**: Eliminates complex runtime setup code that was never actually needed
4. **Better Performance**: Direct process execution without unnecessary abstraction layers

#### Migration Guide:
```bash
# Remove this line from your .env file:
- MCP_RUNTIME_TYPE=binary

# Remove from docker-compose.yml:
- MCP_RUNTIME_TYPE=${MCP_RUNTIME_TYPE}

# That's it! The server now works with any MCP-compatible executable
```

#### Architecture Comparison:

**v1.x (Complex):**
```
HTTP → Runtime Factory → Node/Python/Go/Binary Runtime → Environment Setup → Process
```

**v2.0+ (Simple):**
```
HTTP → Direct Process Execution → MCP Server
```

**Result**: Cleaner, faster, more maintainable, and truly language-agnostic! 🎉

---

### v1.x - Legacy Runtime-Based Architecture
- Multi-runtime support (Node.js, Python, Go, Binary)
- Complex runtime environment setup
- Repository cloning and build capabilities
- Language-specific configuration handling

---

## 🛡️ Technical Details

### Direct Process Bridge (v2.0+)
- **HTTP Core**: Built with Rust + Axum for high performance
- **MCP Bridge**: Converts HTTP requests to JSON-RPC MCP protocol
- **Process Execution**: Direct spawn of MCP server executable
- **Protocol Agnostic**: Works with any language that implements MCP over stdin/stdout
- **No Runtime Dependencies**: Eliminates Node.js/Python/Go environment requirements

### Container Management
- **Docker API**: Direct communication with Docker daemon
- **Lifecycle Management**: Automatic container creation and cleanup
- **Image Flexibility**: Support for any Docker base image
- **Resource Control**: Configurable CPU and memory limits

---

**Lightweight • Secure • Go-Powered**