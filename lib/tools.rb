# frozen_string_literal: true

# Master loader for all MCP tools
require_relative 'tools/base_tool'

# Load all tool categories
require_relative 'tools/projects'
require_relative 'tools/issues'
require_relative 'tools/users'
require_relative 'tools/time_entries'
require_relative 'tools/custom_fields'
require_relative 'tools/versions'
require_relative 'tools/wiki'
require_relative 'tools/attachments'
require_relative 'tools/memberships'
require_relative 'tools/groups'
require_relative 'tools/news'
require_relative 'tools/queries'
require_relative 'tools/reference'
require_relative 'tools/batch'

module RedmineMcpServer
  module Tools
    # Register all fully implemented tools
    def self.register_all_implemented(mcp_server)
      # Fully implemented tools
      Projects.register_all(mcp_server)
      Users.register_all(mcp_server)
      Groups.register_all(mcp_server)
      Issues.register_all(mcp_server)
      TimeEntries.register_all(mcp_server)
      CustomFields.register_all(mcp_server)
      Queries.register_all(mcp_server)
      Batch.register_all(mcp_server)

      # Version tools (fully implemented)
      Versions.register_all(mcp_server)

      # Membership tools (fully implemented)
      Memberships.register_all(mcp_server)

      # Skeleton tools (not yet implemented - uncomment when ready)
      # Wiki.register_all(mcp_server)
      # Attachments.register_all(mcp_server)
      # News.register_all(mcp_server)
      # Reference.register_all(mcp_server)
    end

    # Register ALL tools including skeletons (for testing/development)
    def self.register_all_including_skeletons(mcp_server)
      Projects.register_all(mcp_server)
      Issues.register_all(mcp_server)
      Users.register_all(mcp_server)
      TimeEntries.register_all(mcp_server)
      CustomFields.register_all(mcp_server)
      Queries.register_all(mcp_server)
      Batch.register_all(mcp_server)
      Versions.register_all(mcp_server)
      Wiki.register_all(mcp_server)
      Attachments.register_all(mcp_server)
      Memberships.register_all(mcp_server)
      Groups.register_all(mcp_server)
      News.register_all(mcp_server)
      Reference.register_all(mcp_server)
    end
  end
end
