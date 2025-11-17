# frozen_string_literal: true

# Load environment variables
require 'dotenv/load'

# Load the application
require_relative 'lib/redmine_mcp_server'

# Run the MCP server
run RedmineMcpServer.create_app
