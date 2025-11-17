# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Groups
      # Tool for listing groups from Redmine
      class ListGroupsTool < BaseTool
        def name
          'list_groups'
        end

        def description
          'List all groups from Redmine. Requires admin privileges. Groups are used to organize users and ' \
          'manage permissions across projects.'
        end

        def input_schema
          {
            type: 'object',
            properties: {}
          }
        end

        def execute(_params)
          # Fetch groups
          response = redmine_client.get('/groups')

          groups = response['groups'] || []

          {
            groups: groups,
            total_count: groups.length
          }
        end
      end
    end
  end
end
