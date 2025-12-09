# ChatGPT Actions Mode

This guide explains how to configure Redmine MCP Server for ChatGPT Actions, enabling ChatGPT users to interact with Redmine using their own credentials via OAuth 2.0.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Part 1: Redmine Doorkeeper Setup](#part-1-redmine-doorkeeper-setup)
- [Part 2: MCP Server Configuration](#part-2-mcp-server-configuration)
- [Part 3: OpenAI Custom GPT Setup](#part-3-openai-custom-gpt-setup)
- [Available API Endpoints](#available-api-endpoints)
- [Authentication Flow](#authentication-flow)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## Overview

ChatGPT Mode enables ChatGPT (Custom GPTs) to interact with your Redmine instance through a REST API with OAuth 2.0 authentication. This allows:

- **Per-user authentication**: Each ChatGPT user authenticates with their own Redmine credentials
- **Permission-aware**: All operations respect the user's Redmine permissions
- **Secure**: Uses OAuth 2.0 Authorization Code flow via Redmine's built-in Doorkeeper

### How It Works

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   ChatGPT   │────▶│  MCP Server     │────▶│    Redmine      │
│  (Custom    │     │  (REST API +    │     │  (Doorkeeper    │
│   GPT)      │◀────│   OAuth)        │◀────│   OAuth)        │
└─────────────┘     └─────────────────┘     └─────────────────┘
      │                                            │
      │         OAuth 2.0 Authorization            │
      └────────────────────────────────────────────┘
```

---

## Prerequisites

Before you begin, ensure you have:

1. **Redmine 6.1.0+** with Doorkeeper OAuth enabled
2. **MCP Server** accessible via HTTPS (required for production)
3. **OpenAI ChatGPT Plus** or **Teams** subscription (for Custom GPTs)

---

## Part 1: Redmine Doorkeeper Setup

Redmine 6.1.0+ includes built-in OAuth 2.0 support via Doorkeeper. This section covers how to enable it and create an OAuth application for ChatGPT.

### Step 1: Verify Doorkeeper is Enabled

Doorkeeper is included in Redmine 6.1.0+ but may need to be enabled:

1. Check your `config/application.rb` or Redmine settings
2. Ensure OAuth endpoints are accessible:
   - `https://your-redmine.com/oauth/authorize`
   - `https://your-redmine.com/oauth/token`

### Step 2: Create OAuth Application in Redmine

1. Log in to Redmine as an **administrator**
2. Navigate to **Administration** → **Applications** (OAuth Applications)
3. Click **New Application**
4. Fill in the application details:

| Field | Value |
|-------|-------|
| **Name** | `ChatGPT Integration` (or your preferred name) |
| **Redirect URI** | `https://chat.openai.com/aip/{your-gpt-id}/oauth/callback` |
| **Scopes** | `read write` |
| **Confidential** | Yes (checked) |

> **Note**: You'll get the exact redirect URI from OpenAI when configuring the Custom GPT. You may need to update this after creating your GPT.

5. Click **Create**
6. **Save the Client ID and Client Secret** - you'll need these for OpenAI configuration

### Step 3: Note Your OAuth URLs

Your Redmine OAuth endpoints are:

| Endpoint | URL |
|----------|-----|
| **Authorization URL** | `https://your-redmine.com/oauth/authorize` |
| **Token URL** | `https://your-redmine.com/oauth/token` |

---

## Part 2: MCP Server Configuration

### Environment Variables

Create or update your `.env` file with these ChatGPT-specific settings:

```bash
# ============================================================================
# ChatGPT Actions Configuration
# ============================================================================

# Enable ChatGPT Actions mode (REST API + OAuth support)
CHATGPT_MODE=true

# Require OAuth authentication for API requests
# Set to 'true' for production to enforce Bearer token authentication
CHATGPT_REQUIRE_AUTH=false

# Public URL where the MCP server is accessible
# Must be HTTPS for production ChatGPT integration
OPENAPI_SERVER_URL=https://your-mcp-server.example.com

# OpenAPI schema metadata
OPENAPI_TITLE=Redmine MCP API
OPENAPI_VERSION=1.0.0

# Plugin manifest information
CONTACT_EMAIL=admin@example.com
LEGAL_INFO_URL=https://example.com/legal

# ChatGPT verification token (optional, provided by OpenAI)
CHATGPT_VERIFICATION_TOKEN=your_verification_token
```

### Configuration Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CHATGPT_MODE` | Yes | `false` | Enable ChatGPT REST API endpoints |
| `CHATGPT_REQUIRE_AUTH` | No | `false` | Require Bearer token for all API requests |
| `OPENAPI_SERVER_URL` | Yes | `http://localhost:3100` | Public URL of MCP server |
| `OPENAPI_TITLE` | No | `Redmine MCP API` | API title in OpenAPI schema |
| `OPENAPI_VERSION` | No | `1.0.0` | API version in OpenAPI schema |
| `CONTACT_EMAIL` | No | `support@example.com` | Contact email for plugin |
| `LEGAL_INFO_URL` | No | (empty) | Legal/privacy policy URL |
| `CHATGPT_VERIFICATION_TOKEN` | No | (placeholder) | OpenAI verification token |

### Starting the Server

```bash
# Start with ChatGPT mode enabled
CHATGPT_MODE=true bundle exec falcon serve -b http://0.0.0.0:3100

# Or if using .env file with CHATGPT_MODE=true
bundle exec falcon serve -b http://0.0.0.0:3100
```

### Verify Endpoints

Test that ChatGPT endpoints are working:

```bash
# Health check (should show chatgpt_mode: true)
curl http://localhost:3100/health

# OpenAPI schema
curl http://localhost:3100/api/v1/openapi.json

# Plugin manifest
curl http://localhost:3100/.well-known/ai-plugin.json

# List projects (test API)
curl http://localhost:3100/api/v1/projects
```

---

## Part 3: OpenAI Custom GPT Setup

### Step 1: Create a New Custom GPT

1. Go to [ChatGPT](https://chat.openai.com)
2. Click your profile → **My GPTs** → **Create a GPT**
3. Or go directly to: https://chat.openai.com/gpts/editor

### Step 2: Configure Basic Settings

In the **Create** tab:
- **Name**: `Redmine Assistant` (or your preferred name)
- **Description**: `Manage Redmine projects, issues, and time tracking`
- **Instructions**: Add instructions for how the GPT should interact with Redmine

Example instructions:
```
You are a Redmine project management assistant. You help users:
- View and manage issues (bugs, features, tasks)
- Track time spent on issues
- View project information and memberships
- Query and filter issues

Always confirm before making changes (creating, updating, deleting).
When listing items, summarize the key information clearly.
```

### Step 3: Configure Actions

1. Click the **Configure** tab
2. Scroll down to **Actions** → Click **Create new action**
3. Choose **Import from URL**
4. Enter your OpenAPI schema URL:
   ```
   https://your-mcp-server.example.com/api/v1/openapi.json
   ```
5. Click **Import**

### Step 4: Configure OAuth Authentication

After importing the schema:

1. In the Actions section, click **Authentication**
2. Select **OAuth**
3. Fill in the OAuth settings:

| Field | Value |
|-------|-------|
| **Client ID** | (from Redmine OAuth Application) |
| **Client Secret** | (from Redmine OAuth Application) |
| **Authorization URL** | `https://your-redmine.com/oauth/authorize` |
| **Token URL** | `https://your-redmine.com/oauth/token` |
| **Scope** | `read write` |
| **Token Exchange Method** | `POST request` |

4. Click **Save**

### Step 5: Update Redmine Redirect URI

After saving, OpenAI will show you the **Callback URL**. It looks like:
```
https://chat.openai.com/aip/g-xxxxxxxxxx/oauth/callback
```

1. Copy this URL
2. Go back to Redmine **Administration** → **Applications**
3. Edit your ChatGPT application
4. Update the **Redirect URI** to match exactly
5. Save

### Step 6: Test the Integration

1. In the GPT editor, click **Preview**
2. Try a command like: "List all projects"
3. You should be prompted to sign in to Redmine
4. After authorizing, the GPT should be able to access Redmine data

---

## Available API Endpoints

### REST Endpoints

When ChatGPT Mode is enabled, these REST endpoints are available:

| Method | Endpoint | Tool | Description |
|--------|----------|------|-------------|
| GET | `/api/v1/projects` | list_projects | List all accessible projects |
| GET | `/api/v1/projects/{id}` | get_project | Get project details |
| POST | `/api/v1/projects` | create_project | Create a new project |
| PUT | `/api/v1/projects/{id}` | update_project | Update a project |
| DELETE | `/api/v1/projects/{id}` | delete_project | Delete a project |
| GET | `/api/v1/issues` | list_issues | List issues with filters |
| GET | `/api/v1/issues/{id}` | get_issue | Get issue details |
| POST | `/api/v1/issues` | create_issue | Create a new issue |
| PUT | `/api/v1/issues/{id}` | update_issue | Update an issue |
| DELETE | `/api/v1/issues/{id}` | delete_issue | Delete an issue |
| GET | `/api/v1/time_entries` | list_time_entries | List time entries |
| GET | `/api/v1/time_entries/{id}` | get_time_entry | Get time entry details |
| POST | `/api/v1/time_entries` | create_time_entry | Log time |
| GET | `/api/v1/users` | list_users | List users |
| GET | `/api/v1/users/{id}` | get_user | Get user details |
| GET | `/api/v1/versions` | list_versions | List versions |
| GET | `/api/v1/versions/{id}` | get_version | Get version details |
| POST | `/api/v1/versions` | create_version | Create a version |
| GET | `/api/v1/memberships` | list_memberships | List project memberships |
| GET | `/api/v1/groups` | list_groups | List groups |
| GET | `/api/v1/queries` | list_queries | List saved queries |
| GET | `/api/v1/custom_fields` | list_custom_fields | List custom fields |

### Generic Tool Endpoint

For tools not mapped to REST endpoints:
```
POST /api/v1/tools/{tool_name}
Content-Type: application/json

{
  "arguments": {
    "param1": "value1",
    "param2": "value2"
  }
}
```

### System Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check (includes `chatgpt_mode` status) |
| `GET /.well-known/ai-plugin.json` | ChatGPT plugin manifest |
| `GET /api/v1/openapi.json` | OpenAPI 3.1.0 schema (JSON) |
| `GET /api/v1/openapi.yaml` | OpenAPI 3.1.0 schema (YAML) |

---

## Authentication Flow

### OAuth 2.0 Authorization Code Flow

```
┌──────────┐                              ┌─────────────┐                              ┌──────────┐
│  ChatGPT │                              │ MCP Server  │                              │ Redmine  │
└────┬─────┘                              └──────┬──────┘                              └────┬─────┘
     │                                           │                                          │
     │  1. User asks to access Redmine           │                                          │
     ├──────────────────────────────────────────▶│                                          │
     │                                           │                                          │
     │  2. Redirect to Redmine OAuth             │                                          │
     │◀──────────────────────────────────────────┤                                          │
     │                                           │                                          │
     │  3. User authorizes at Redmine login      │                                          │
     ├─────────────────────────────────────────────────────────────────────────────────────▶│
     │                                           │                                          │
     │  4. Redmine returns authorization code    │                                          │
     │◀─────────────────────────────────────────────────────────────────────────────────────┤
     │                                           │                                          │
     │  5. Exchange code for access token        │                                          │
     ├─────────────────────────────────────────────────────────────────────────────────────▶│
     │                                           │                                          │
     │  6. Return access token                   │                                          │
     │◀─────────────────────────────────────────────────────────────────────────────────────┤
     │                                           │                                          │
     │  7. API request with Bearer token         │                                          │
     ├──────────────────────────────────────────▶│                                          │
     │                                           │  8. Forward request with Bearer token    │
     │                                           ├─────────────────────────────────────────▶│
     │                                           │                                          │
     │                                           │  9. Validate token, return data          │
     │                                           │◀─────────────────────────────────────────┤
     │  10. Return response to ChatGPT           │                                          │
     │◀──────────────────────────────────────────┤                                          │
     │                                           │                                          │
```

### How Token Validation Works

1. ChatGPT includes `Authorization: Bearer <token>` header in API requests
2. MCP Server's OAuth middleware extracts the token
3. MCP Server forwards the token to Redmine API
4. Redmine's Doorkeeper validates the token internally
5. Request proceeds with the authenticated user's permissions

---

## Troubleshooting

### Common Issues

#### "ChatGPT mode not enabled"

**Cause**: `CHATGPT_MODE` is not set to `true`

**Solution**:
```bash
# Add to .env
CHATGPT_MODE=true

# Or set environment variable
export CHATGPT_MODE=true
```

#### OAuth redirect URI mismatch

**Cause**: The redirect URI in Redmine doesn't match OpenAI's callback URL

**Solution**:
1. In ChatGPT GPT Editor, go to Actions → Authentication
2. Copy the exact Callback URL shown
3. Update the Redirect URI in Redmine Admin → Applications

#### 401 Unauthorized errors

**Cause**: Invalid or expired OAuth token

**Solution**:
- Have the user re-authenticate by asking them to "sign out and sign in again"
- Check that the Client ID and Secret match between Redmine and ChatGPT

#### OpenAPI schema import fails

**Cause**: MCP Server not accessible or not using HTTPS

**Solution**:
1. Ensure server is publicly accessible
2. Use HTTPS (required for production)
3. Test the URL directly: `curl https://your-server/api/v1/openapi.json`

### Testing with cURL

```bash
# Test without authentication (if CHATGPT_REQUIRE_AUTH=false)
curl https://your-server/api/v1/projects

# Test with Bearer token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://your-server/api/v1/issues

# Create an issue
curl -X POST \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"project_id": 1, "tracker_id": 1, "subject": "Test issue"}' \
     https://your-server/api/v1/issues
```

### Debug Mode

Enable debug logging for more details:

```bash
LOG_LEVEL=debug CHATGPT_MODE=true bundle exec falcon serve
```

---

## Security Considerations

### HTTPS Requirement

- **Production**: Must use HTTPS for OAuth to work with ChatGPT
- **Development**: HTTP is acceptable for local testing only
- Use a reverse proxy (nginx, Caddy) or cloud provider for SSL termination

### Token Security

- OAuth tokens are passed through but never stored by MCP Server
- Tokens are validated by Redmine's Doorkeeper on each request
- Consider setting `CHATGPT_REQUIRE_AUTH=true` to enforce authentication

### Network Security

- Deploy MCP Server in a trusted network zone
- Use firewall rules to restrict access if needed
- Consider rate limiting for production deployments

### Redmine Permissions

- All API operations respect Redmine's permission system
- Users can only access projects/issues they have permission to view
- Write operations require appropriate Redmine roles

### Recommendations

1. **Use HTTPS** in production
2. **Set `CHATGPT_REQUIRE_AUTH=true`** to enforce OAuth
3. **Limit OAuth scopes** if you don't need write access
4. **Monitor access logs** for unusual activity
5. **Rotate OAuth credentials** periodically
