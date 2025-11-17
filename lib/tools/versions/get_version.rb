# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Versions
      # Tool for getting a specific version from Redmine
      class GetVersionTool < BaseTool
        def name
          'get_version'
        end

        def description
          'Get details of a specific project version/milestone including status, dates, description, and associated issues.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              version_id: {
                type: 'integer',
                description: 'Version ID to retrieve (required)'
              }
            },
            required: %w[version_id]
          }
        end

        def execute(params)
          validate_required_params(params, :version_id)

          # Fetch version
          response = redmine_client.get("/versions/#{params[:version_id]}")

          response['version'] || response
        end
      end
    end
  end
end
