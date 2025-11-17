# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      class GetIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'get_issue'
        end

        def description
          'Get detailed information about a specific issue by ID. Includes issue fields, custom fields, ' \
          'and optionally attachments, relations, journals (history), and watchers.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Issue ID'
              },
              include: {
                type: 'string',
                description: 'Comma-separated list: attachments,relations,changesets,journals,watchers'
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          issue_id = params[:id]
          query_params = {}
          query_params[:include] = params[:include] if params[:include]

          response = redmine_client.get("/issues/#{issue_id}", query_params)
          response['issue'] || response
        end
      end
    end
  end
end
