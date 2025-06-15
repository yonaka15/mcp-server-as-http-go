# MCP HTTP Server - Universal MCP Bridge

A **universal** HTTP server that provides RESTful API access to any [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) server using [`mcp-server-as-http-core`](https://github.com/yonaka15/mcp-server-as-http-core) (Rust). **Defaults to GitHub MCP Server** with support for multiple MCP servers.

> **🌐 Universal**: Support for any MCP server (GitHub, Code Sandbox, and more)  
> **⚡ Lightweight**: Minimal Alpine-based images (55-85MB)  
> **🐙 GitHub First**: Optimized for GitHub MCP Server by default  
> **🔧 Flexible**: Easy switching between different MCP servers  
> **🚀 Fast**: Direct binary execution with no overhead

## 🏗️ Architecture

```
mcp-http-server/
├── Dockerfile.github           # GitHub MCP optimized (55MB)
├── Dockerfile                  # Universal (65MB) 
├── Dockerfile.code-sandbox     # Code Sandbox (85MB)
├── docker-compose.github.yml   # GitHub MCP (recommended)
├── docker-compose.yml          # Universal configuration
├── mcp_servers.config.json     # Default: GitHub MCP Server
├── mcp_code-sandbox.config.json # Code Sandbox configuration
├── .env                        # Default: GitHub settings
└── USAGE.md                    # Detailed usage guide
```

**Components:**
- **HTTP Core**: Rust binary for HTTP/JSON-RPC bridge (~10MB)
- **GitHub MCP**: Official GitHub MCP Server binary (~15MB)  
- **Runtime**: Alpine Linux with Go environment (~40MB base)
- **Bridge**: **Direct process execution** - language agnostic protocol

**Universal Flow:**
```
HTTP Request (JSON-RPC) → MCP HTTP Server → Direct Process Spawn → Any MCP Server → JSON-RPC Response → HTTP Response
```

## 🚀 Quick Start

### GitHub MCP Server (Default & Recommended)

```bash
# Clone repository
git clone https://github.com/yonaka15/mcp-http-server.git
cd mcp-http-server

# Set your GitHub token
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"

# Start GitHub MCP Server (lightest & fastest)
docker-compose -f docker-compose.github.yml up -d

# Test health
curl -f http://localhost:3000/health

# List GitHub tools
curl -X POST http://localhost:3000/api/v1 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command": "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/list\", \"params\": {}}"}'
```

### Other MCP Servers

```bash
# Code Sandbox MCP Server
cp .env.code-sandbox .env
docker-compose -f docker-compose.code-sandbox.yml up -d

# Universal (supports multiple servers)
docker-compose up -d
```

## 🛠️ GitHub MCP Server API Examples

### Get Your GitHub Profile
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 1,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"get_me\",
        \"arguments\": {}
      }
    }"
  }'
```

### List Repository Issues
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 2,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"list_issues\",
        \"arguments\": {
          \"owner\": \"your-username\",
          \"repo\": \"your-repo\",
          \"state\": \"open\"
        }
      }
    }"
  }'
```

### Create New Issue
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 3,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"create_issue\",
        \"arguments\": {
          \"owner\": \"your-username\",
          \"repo\": \"your-repo\",
          \"title\": \"New feature request\",
          \"body\": \"Description of the feature...\"
        }
      }
    }"
  }'
```

### Get File Contents
```bash
curl -X POST http://localhost:3000/api/v1 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "{
      \"jsonrpc\": \"2.0\",
      \"id\": 4,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"get_file_contents\",
        \"arguments\": {
          \"owner\": \"your-username\",
          \"repo\": \"your-repo\",
          \"path\": \"README.md\"
        }
      }
    }"
  }'
```

## ⚙️ Configuration

### Core Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_SERVER_NAME` | `github` | MCP server name from config |
| `MCP_CONFIG_FILE` | `mcp_servers.config.json` | MCP server configuration file |
| `PORT` | `3000` | HTTP server port |
| `HTTP_API_KEY` | - | Bearer token for authentication |
| `DISABLE_AUTH` | `false` | Enable/disable authentication |
| `RUST_LOG` | `info` | Log level (error, warn, info, debug, trace) |

### GitHub MCP Server Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | - | **Required** GitHub PAT |
| `GITHUB_TOOLSETS` | `all` | Available toolsets (repos,issues,pull_requests,etc.) |
| `GITHUB_READ_ONLY` | `false` | Enable read-only mode |
| `GITHUB_DYNAMIC_TOOLSETS` | `false` | Enable dynamic toolset discovery |
| `GITHUB_HOST` | - | GitHub Enterprise Server hostname |

## 🔧 Available GitHub Tools

### Repository Management
- **`get_file_contents`**: Get file/directory contents
- **`create_or_update_file`**: Create or update files
- **`list_branches`**: List repository branches
- **`create_branch`**: Create new branch
- **`list_commits`**: Get commit history
- **`get_commit`**: Get commit details
- **`search_repositories`**: Search repositories
- **`create_repository`**: Create new repository
- **`fork_repository`**: Fork repository

### Issue Management
- **`list_issues`**: List and filter issues
- **`get_issue`**: Get issue details
- **`create_issue`**: Create new issue
- **`update_issue`**: Update existing issue
- **`add_issue_comment`**: Add issue comment
- **`get_issue_comments`**: Get issue comments
- **`search_issues`**: Search issues and PRs

### Pull Request Operations
- **`list_pull_requests`**: List pull requests
- **`get_pull_request`**: Get PR details
- **`create_pull_request`**: Create new PR
- **`update_pull_request`**: Update existing PR
- **`merge_pull_request`**: Merge pull request
- **`get_pull_request_files`**: Get changed files
- **`get_pull_request_reviews`**: Get PR reviews
- **`create_pull_request_review`**: Create PR review

### Security & Code Analysis
- **`list_code_scanning_alerts`**: List code scanning alerts
- **`get_code_scanning_alert`**: Get specific alert
- **`list_secret_scanning_alerts`**: List secret scanning alerts
- **`get_secret_scanning_alert`**: Get specific secret alert

### User & Search
- **`get_me`**: Get authenticated user details
- **`search_users`**: Search GitHub users
- **`search_code`**: Search code across repositories

## 🐳 Deployment Options

### 1. GitHub MCP Only (Recommended)
```bash
# Lightest option: ~55MB, no Docker CLI
docker-compose -f docker-compose.github.yml up -d
```

### 2. Universal Support
```bash
# Supports multiple MCP servers: ~65MB
docker-compose up -d
```

### 3. Code Sandbox
```bash
# Full Docker support: ~85MB
cp .env.code-sandbox .env
docker-compose -f docker-compose.code-sandbox.yml up -d
```

## 📦 Image Sizes & Performance

| Configuration | Image Size | Memory Usage | Startup Time | Use Case |
|---------------|------------|--------------|--------------|----------|
| **GitHub Only** | ~55MB | 64-128MB | ~2s | GitHub integration only |
| **Universal** | ~65MB | 64-128MB | ~3s | Multiple MCP servers |
| **Code Sandbox** | ~85MB | 128-256MB | ~5s | Code execution + GitHub |

## 🚀 Production Deployment

### With Authentication
```bash
# Set environment variables
export HTTP_API_KEY="your-secret-api-key"
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-token"
export DISABLE_AUTH=false

# Deploy
docker-compose -f docker-compose.github.yml up -d
```

### Health Monitoring
```bash
# Health check
curl -f http://localhost:3000/health

# View logs
docker-compose logs -f mcp-http-server

# Resource monitoring
docker stats mcp-http-server
```

### Security Best Practices
```bash
# Use fine-grained GitHub PAT with minimal scopes
# Enable read-only mode for monitoring use cases
export GITHUB_READ_ONLY=true

# Restrict toolsets to needed functionality
export GITHUB_TOOLSETS="repos,issues"

# Enable authentication
export DISABLE_AUTH=false
```

## 🔒 Security

### GitHub Integration
- **Fine-grained PAT**: Use minimal required scopes
- **Read-only Mode**: `GITHUB_READ_ONLY=true` for safer operations
- **Toolset Restriction**: Limit available tools via `GITHUB_TOOLSETS`
- **Enterprise Support**: Custom `GITHUB_HOST` for GitHub Enterprise

### HTTP Server
- **Bearer Authentication**: `HTTP_API_KEY` protection
- **Non-root Execution**: All processes run as unprivileged user
- **HTTPS Ready**: Production deployment with reverse proxy
- **CORS Support**: Configurable cross-origin requests

### Container Security
- **Minimal Attack Surface**: Alpine-based images
- **No Docker Socket**: GitHub MCP doesn't require Docker access
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Built-in monitoring

## 🎯 Use Cases

### AI-Powered Development
- **GitHub Copilot Integration**: Enhanced context with live GitHub data
- **Code Review Automation**: AI agents analyzing PRs and issues
- **Repository Analysis**: AI-driven insights from GitHub data
- **Automated Workflows**: AI triggering GitHub actions

### Developer Tools
- **IDE Extensions**: GitHub integration for editors
- **CLI Tools**: Command-line GitHub operations
- **Dashboard Creation**: Custom GitHub analytics
- **Notification Systems**: Real-time GitHub event processing

### Enterprise Integration
- **GitHub Enterprise**: Connect to self-hosted GitHub
- **Monitoring Dashboards**: Repository health monitoring
- **Compliance Tools**: Security and audit automation
- **Development Metrics**: Team productivity analytics

## 🔍 API Response Examples

### GitHub User Profile
```json
{
  "result": {
    "content": [
      {
        "type": "text",
        "text": "User: octocat\nName: The Octocat\nPublic repos: 8\nFollowers: 9999"
      }
    ]
  }
}
```

### Repository Issues
```json
{
  "result": {
    "content": [
      {
        "type": "text", 
        "text": "Found 3 open issues:\n#1: Bug in login\n#2: Feature request\n#3: Documentation update"
      }
    ]
  }
}
```

## 📋 Switching Between MCP Servers

### To Code Sandbox
```bash
# Backup current config
cp .env .env.github.bak
cp mcp_servers.config.json mcp_github.config.json.bak

# Switch to Code Sandbox
cp .env.code-sandbox .env
cp mcp_code-sandbox.config.json mcp_servers.config.json

# Restart with Code Sandbox
docker-compose down
docker-compose -f docker-compose.code-sandbox.yml up -d
```

### Back to GitHub
```bash
# Restore GitHub config
cp .env.github.bak .env
cp mcp_github.config.json.bak mcp_servers.config.json

# Restart with GitHub MCP
docker-compose down
docker-compose -f docker-compose.github.yml up -d
```

## 🛡️ Technical Architecture

### HTTP Bridge (Universal)
- **HTTP Core**: Built with Rust + Axum for high performance
- **MCP Bridge**: Converts HTTP requests to JSON-RPC MCP protocol  
- **Process Execution**: Direct spawn of any MCP server executable
- **Protocol Agnostic**: Works with any language implementing MCP over stdin/stdout
- **Zero Runtime Dependencies**: No Node.js/Python/Go runtime requirements

### GitHub MCP Integration
- **Official Server**: Uses GitHub's official MCP server
- **Real-time API**: Direct GitHub API integration
- **OAuth Support**: Secure authentication with GitHub
- **Fine-grained Permissions**: Granular access control
- **Enterprise Ready**: GitHub Enterprise Server support

### Scalability
- **Stateless Design**: Easy horizontal scaling
- **Resource Efficient**: Minimal memory footprint
- **Fast Startup**: Sub-second cold starts
- **Health Monitoring**: Built-in health checks
- **Graceful Shutdown**: Proper cleanup on termination

---

**Universal • Secure • GitHub-First**

For detailed usage instructions, see [USAGE.md](USAGE.md).
