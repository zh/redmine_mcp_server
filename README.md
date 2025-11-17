# Redmine MCP Server

A Model Context Protocol (MCP) server that provides AI assistants with access to Redmine project management software via its REST API.

## Features

- **Full Redmine API Access**: Interact with projects, issues, users, time entries, and more
- **MCP Protocol**: Standard protocol for AI-to-tool communication
- **Standalone Server**: Independent deployment, connects to any Redmine instance
- **Secure**: API key-based authentication with Redmine
- **Flexible**: Configurable via environment variables

## Prerequisites

- Ruby 3.1 or higher
- Access to a Redmine instance (5.0+) with REST API enabled
- Redmine API key (obtain from /my/account page in Redmine)

### Optional Redmine Plugins

Some MCP tools require the **Redmine Extended API plugin** for advanced functionality:

- **Custom Fields CRUD**: `create_custom_field`, `update_custom_field`, `delete_custom_field`
- **Queries CRUD**: `create_query`, `update_query`, `delete_query`
- **Bulk Time Entries**: `bulk_create_time_entries`

**Installation**:
```bash
cd /path/to/redmine/plugins
git clone https://github.com/agileware/redmine_extended_api.git
cd /path/to/redmine
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
systemctl restart redmine
```

See [redmine_extended_api](https://github.com/agileware/redmine_extended_api) for details.

**Note**: All other MCP tools work with standard Redmine REST API (no plugins required).

## Installation

1. Clone or download this repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Copy the example environment file and configure:
   ```bash
   cp .env.example .env
   ```

4. Edit `.env` and set your Redmine credentials:
   ```bash
   REDMINE_URL=https://your-redmine-instance.com
   REDMINE_API_KEY=your_api_key_here
   ```

## Configuration

All configuration is done via environment variables in the `.env` file:

### Required Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `REDMINE_URL` | Base URL of your Redmine instance | - | Yes |
| `REDMINE_API_KEY` | Your Redmine API key | - | Yes |

### Server Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MCP_PORT` | Port for the MCP server | 3100 | No |
| `MCP_HOST` | Host to bind to | localhost | No |
| `RACK_ENV` | Environment (development/production) | development | No |
| `LOG_LEVEL` | Logging level (debug/info/warn/error) | info | No |

### Performance Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `HTTP_TIMEOUT` | HTTP request timeout in seconds | 30 | No |
| `HTTP_READ_TIMEOUT` | HTTP read timeout in seconds | 60 | No |
| `FALCON_PROCESSES` | Number of server worker processes | 1 | No |
| `METRICS_SLOW_THRESHOLD` | Slow request threshold in seconds | 1.0 | No |

**Note**: Connection pooling and compression (gzip/deflate) are handled automatically by the async HTTP client.

### Getting Your Redmine API Key

1. Log into your Redmine instance
2. Navigate to "My Account" (/my/account)
3. Look for "API access key" on the right sidebar
4. Click "Show" to reveal your key, or "Reset" to generate a new one
5. Copy the key to your `.env` file

## Usage

### Starting the Server

The server uses [Falcon](https://socketry.github.io/falcon/), a high-performance async web server.

**Development mode** (with auto-reload):
```bash
bundle exec rerun -- falcon serve --bind http://localhost:3100
```

**Production mode**:
```bash
bundle exec falcon serve --bind http://localhost:3100
```

The server will start with multiple worker processes (8 by default) for optimal performance. You can control the number of workers by setting `FALCON_PROCESSES` in your `.env` file.

### Connecting from MCP Clients

Add the server to your MCP client configuration (e.g., Claude Desktop):

```json
{
  "mcpServers": {
    "redmine": {
      "command": "bundle",
      "args": ["exec", "falcon", "serve", "--bind", "http://localhost:3100"],
      "cwd": "/path/to/redmine_mcp_server"
    }
  }
}
```

Or connect to the running server:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "http://localhost:3100/mcp"
    }
  }
}
```

## Available Tools

### Current Status

- **53 Fully Implemented Tools** (Projects, Memberships, Versions, Issues, Users, Groups, Time Entries, Custom Fields, Queries, Batch Operations)
- **21 Skeleton Tools** (structure defined, ready for implementation)
- **74 Total Tools** across 14 resource categories

### Implemented Tools ✅

#### Project Operations (5 tools)
- `list_projects` - List all accessible projects with pagination and filtering
- `get_project` - Get detailed information about a specific project
- `create_project` - Create a new project
- `update_project` - Update an existing project
- `delete_project` - Delete a project

#### Membership Operations (5 tools)
- `list_memberships` - List all members of a project
- `get_membership` - Get details of a specific membership
- `create_membership` - Add a user/group to a project with roles
- `update_membership` - Update roles for a project member
- `delete_membership` - Remove a user/group from a project

#### Version/Milestone Operations (5 tools)
- `list_versions` - List versions/milestones for a project
- `get_version` - Get details of a specific version
- `create_version` - Create a new version/milestone
- `update_version` - Update an existing version
- `delete_version` - Delete a version

#### Issue Operations (13 tools)
- `list_issues` - List issues with filtering, sorting, and pagination (supports query_id for saved queries)
- `get_issue` - Get detailed information about a specific issue
- `create_issue` - Create a new issue in a project
- `update_issue` - Update an existing issue
- `delete_issue` - Delete an issue
- `add_issue_watcher` - Add a watcher to an issue
- `remove_issue_watcher` - Remove a watcher from an issue
- `get_issue_relations` - Get all relations for an issue (blocks, relates to, etc.)
- `create_issue_relation` - Create a relation between two issues
- `delete_issue_relation` - Delete an issue relation
- `get_issue_journals` - Get the change history (journals) for an issue
- `copy_issue` - Copy an issue to another project or within the same project
- `move_issue` - Move an issue to a different project

#### User Operations (5 tools)
- `list_users` - List all users with filtering and pagination
- `get_user` - Get detailed information about a specific user
- `create_user` - Create a new user account (requires admin)
- `update_user` - Update an existing user account
- `delete_user` - Delete a user account

#### Group Operations (5 tools)
- `list_groups` - List all groups (requires admin)
- `get_group` - Get details of a specific group including members
- `create_group` - Create a new group with optional initial members
- `update_group` - Update group details and membership
- `delete_group` - Delete a group

#### Time Entry Operations (6 tools)
- `list_time_entries` - List time entries with filtering by user, project, issue, or date range
- `get_time_entry` - Get detailed information about a specific time entry
- `create_time_entry` - Log time on an issue or project
- `update_time_entry` - Update an existing time entry
- `delete_time_entry` - Delete a time entry
- `bulk_create_time_entries` - Create multiple time entries in a single request (requires Extended API plugin)

#### Custom Field Operations (4 tools)
- `list_custom_fields` - List all custom fields with their configuration
- `create_custom_field` - Create a new custom field (requires admin, Extended API plugin)
- `update_custom_field` - Update an existing custom field (requires admin, Extended API plugin)
- `delete_custom_field` - Delete a custom field (requires admin, Extended API plugin)

**Note:** Custom field values can be set in issues, projects, users, and other entities using the `custom_field_values` or `custom_fields` parameter in their respective create/update tools.

#### Query Operations (4 tools)
- `list_queries` - List all accessible queries (saved filters) with pagination
- `create_query` - Create a new query with filters, visibility, and columns (requires Extended API plugin)
- `update_query` - Update an existing query (requires Extended API plugin)
- `delete_query` - Delete a query (requires Extended API plugin)

**Query Features:**
- **Saved Filters**: Queries are saved filters for issues, time entries, projects, etc.
- **Filter Operators**: Supports all Redmine operators (`=`, `!=`, `>=`, `<=`, `~`, `!~`, `o` (open), `c` (closed), `t` (today), `w` (week), `m` (month), `<t+N`, `>t-N`)
- **Visibility Levels**: Private (0), Roles (1), Public (2)
- **Query Types**: IssueQuery, ProjectQuery, TimeEntryQuery
- **Execution**: Use `list_issues` with `query_id` parameter to execute saved queries
- **Permissions**: Users manage own private queries; `manage_public_queries` for project queries; admin for global queries

**Example - Create and execute a query:**
```json
// 1. Create a query for late issues
{
  "name": "create_query",
  "params": {
    "name": "Late Issues Before May",
    "type": "IssueQuery",
    "visibility": 0,
    "filters": {
      "due_date": {"operator": "<=", "values": ["2025-05-01"]},
      "status_id": {"operator": "o"}
    },
    "column_names": ["id", "subject", "status", "due_date"],
    "sort_criteria": [["due_date", "asc"]]
  }
}
// Returns: {"id": 10, "name": "Late Issues Before May", ...}

// 2. Execute the saved query
{
  "name": "list_issues",
  "params": {
    "query_id": 10
  }
}
// Returns filtered and sorted issues based on the saved query
```

#### Batch Operations (1 tool)
- `batch_execute` - Execute multiple MCP tools concurrently for improved performance

### Skeleton Tools (Ready for Implementation) ⏳

All skeleton tools are defined with complete schemas but raise `NotImplementedError`:

- **Wiki Pages** (6 tools): list, get, create, update, delete, versions
- **Attachments** (3 tools): upload, get, delete
- **News** (2 tools): list, get
- **Reference Data** (7 tools): trackers, statuses, priorities, activities, roles, search

See [TOOLS.md](TOOLS.md) for complete tool documentation.

## Performance & Monitoring

The MCP server includes built-in performance optimizations and monitoring capabilities.

### Performance Features

#### HTTP Optimizations (Async Architecture)
- **Automatic Connection Pooling**: Async HTTP client manages connections automatically
- **HTTP Keep-Alive**: Efficient connection reuse with automatic management
- **Response Compression**: Automatic gzip/deflate compression (70-80% bandwidth reduction)
- **Fiber-Based Concurrency**: Lightweight concurrent operations using Ruby fibers
- **Configurable Timeouts**: Separate settings for connection and read operations
- **Multi-Process Server**: Falcon runs multiple worker processes (configurable) for true parallelism

#### Batch Execution
Use the `batch_execute` tool to run multiple operations concurrently:

```json
{
  "name": "batch_execute",
  "params": {
    "calls": [
      { "name": "get_issue", "params": { "id": 123 } },
      { "name": "get_issue", "params": { "id": 456 } },
      { "name": "list_time_entries", "params": { "issue_id": 123 } }
    ],
    "max_concurrency": 5
  }
}
```

**Performance gain**: Up to 20x faster for independent operations compared to sequential execution.

### Metrics Endpoints

Monitor server performance in real-time:

**Prometheus Format** (for monitoring tools like Grafana):
```bash
curl http://localhost:3100/metrics
```

**Tool Metrics** (JSON):
```bash
curl http://localhost:3100/metrics/tools
```

Returns:
```json
{
  "tools": [
    {
      "tool": "list_issues",
      "total_calls": 42,
      "success_count": 40,
      "error_count": 2,
      "total_duration_ms": 1250.5,
      "avg_duration_ms": 29.77,
      "errors_by_type": { "NotFoundError": 2 }
    }
  ]
}
```

**API Metrics** (JSON):
```bash
curl http://localhost:3100/metrics/api
```

**Slow Requests** (JSON):
```bash
curl http://localhost:3100/metrics/slow
```

Lists requests exceeding the slow threshold (default: 1.0 second).

### Performance Configuration

Configure performance settings in `.env`:

```bash
# HTTP timeouts in seconds
HTTP_TIMEOUT=30          # Request timeout
HTTP_READ_TIMEOUT=60     # Read timeout

# Server configuration
FALCON_PROCESSES=1       # Number of worker processes (increase for production)

# Metrics
METRICS_SLOW_THRESHOLD=1.0  # Slow request threshold in seconds
```

**Note**: The async HTTP client handles connection pooling and compression automatically.
No manual configuration needed for these features.

See [docs/PERFORMANCE.md](docs/PERFORMANCE.md) for detailed performance tuning guide.

## Development

### Running Tests

All implemented tools have comprehensive RSpec test coverage (330+ tests).

**Run all tests:**
```bash
bundle exec rspec
```

**Run specific tool category:**
```bash
bundle exec rspec spec/tools/time_entries/
bundle exec rspec spec/tools/custom_fields/
bundle exec rspec spec/tools/queries/
```

**Test coverage includes:**
- Tool metadata validation
- Success cases with minimum and optional parameters
- Required parameter validation
- Error handling (auth, validation, not found)

See [TOOLS.md](TOOLS.md#testing-guide) for detailed testing guide.

### Code Quality

```bash
bundle exec rubocop
bundle exec rubocop --autocorrect
```

### Project Structure

```
redmine_mcp_server/
├── lib/
│   ├── redmine_mcp_server.rb    # Main application
│   ├── async_redmine_client.rb  # Async Redmine API client
│   ├── tools/                    # MCP tools (operations)
│   │   ├── base_tool.rb
│   │   ├── projects/             # Project CRUD
│   │   ├── issues/               # Issue operations
│   │   └── ...
│   └── resources/                # MCP resources (data sources)
├── spec/                         # RSpec tests
├── Gemfile                       # Ruby dependencies
├── config.ru                     # Rack configuration
└── .env                          # Environment configuration
```

## Architecture

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│             │         │                  │         │             │
│  AI Client  │ ◄─MCP──►│  Redmine MCP     │ ◄─HTTP──►│  Redmine    │
│  (Claude)   │         │     Server       │         │   Instance  │
│             │         │                  │         │             │
└─────────────┘         └──────────────────┘         └─────────────┘
```

- **AI Client**: Claude or other MCP-compatible AI assistant
- **Redmine MCP Server**: This application (translates MCP to Redmine API)
- **Redmine Instance**: Your Redmine installation

## Troubleshooting

### Connection Issues

**Error: "Missing required environment variable: REDMINE_URL"**
- Make sure you have a `.env` file in the project root
- Verify all required variables are set

**Error: "Connection refused" or "Timeout"**
- Check that your `REDMINE_URL` is correct and accessible
- Verify that Redmine's REST API is enabled (Administration → Settings → API)
- Test API access manually: `curl -H "X-Redmine-API-Key: YOUR_KEY" https://your-redmine.com/users/current.json`

**Error: "401 Unauthorized"**
- Verify your API key is correct
- Check that the user associated with the API key has appropriate permissions
- Generate a new API key if necessary

### Server Issues

**Error: "Address already in use"**
- Another process is using port 3100
- Change the port in `.env`: `MCP_PORT=3101`
- Or stop the other process: `lsof -ti:3100 | xargs kill -9`

## Security Considerations

- **API Keys**: Never commit `.env` files to version control
- **Network**: In production, use HTTPS for Redmine connections
- **Firewall**: Restrict MCP server access to trusted clients only
- **Permissions**: Use Redmine API keys with appropriate permissions (principle of least privilege)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass and code passes rubocop
5. Submit a pull request

## License

Copyright © 2025 Stoyan Zhekov <zh@zhware.net>

This project is available for use under the MIT License.

## Acknowledgments

- Built with [mcp_on_ruby](https://github.com/rubyonai/mcp_on_ruby)
- Powered by [Redmine](https://www.redmine.org/) REST API
- Uses [Async](https://socketry.github.io/async/) for high-performance concurrent HTTP communication
- Served by [Falcon](https://socketry.github.io/falcon/), a modern async web server

## Support

For issues, questions, or contributions:
- GitHub Issues: [Create an issue](https://github.com/agileware/redmine_mcp_server/issues)
- Documentation: [Redmine REST API](https://www.redmine.org/projects/redmine/wiki/rest_api)

## Roadmap

- [x] Stage 1: Project structure and configuration
- [x] Stage 2: Redmine API client
- [x] Stage 3: MCP base infrastructure
- [x] Stage 4: Project CRUD operations
- [x] Stage 4.5: Project copy, membership, and version management
- [x] Stage 4.6: Issue management tools (13 tools)
- [x] Stage 4.7: User management tools (5 tools)
- [x] Stage 4.8: Group management tools (5 tools)
- [x] Stage 5: Time entry tools (6 tools including bulk operations)
- [x] Stage 5.5: Custom field management tools (4 tools)
- [x] Stage 5.6: Performance optimizations (connection pooling, compression, metrics, batch execution)
- [x] Stage 5.7: Query management tools (4 tools for saved filters)
- [ ] Stage 6: Wiki and attachment tools
- [ ] Stage 7: News and reference data tools
- [ ] Stage 8: Advanced features (caching, webhooks)
- [ ] Stage 9: Comprehensive test coverage
- [ ] Stage 10: Production deployment guides
