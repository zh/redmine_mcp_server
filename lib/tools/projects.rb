# frozen_string_literal: true

# Load all project tools
require_relative 'projects/list_projects'
require_relative 'projects/get_project'
require_relative 'projects/create_project'
require_relative 'projects/update_project'
require_relative 'projects/delete_project'

module RedmineMcpServer
  module Tools
    module Projects
      # Register all project tools with the MCP server
      def self.register_all(mcp_server)
        [
          ListProjectsTool.new,
          GetProjectTool.new,
          CreateProjectTool.new,
          UpdateProjectTool.new,
          DeleteProjectTool.new
        ].each do |tool|
          mcp_server.register_tool(tool)
        end
      end
    end
  end
end
