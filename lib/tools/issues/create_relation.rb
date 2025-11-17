# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer
  module Tools
    module Issues
      class CreateIssueRelationTool < RedmineMcpServer::Tools::BaseTool
        def name = 'create_issue_relation'
        def description = 'Create a relation between two issues'

        def input_schema
          {
            type: 'object',
            properties: {
              issue_id: { type: 'integer', description: 'Source issue ID' },
              issue_to_id: { type: 'integer', description: 'Target issue ID' },
              relation_type: {
                type: 'string',
                description: 'Type of relation',
                enum: %w[relates duplicates duplicated blocks blocked precedes follows copied_to copied_from]
              },
              delay: { type: 'integer', description: 'Delay in days (only for precedes/follows)' }
            },
            required: %w[issue_id issue_to_id relation_type]
          }
        end

        def execute(params)
          validate_required_params(params, :issue_id, :issue_to_id, :relation_type)

          issue_id = params[:issue_id]
          relation_data = {
            issue_to_id: params[:issue_to_id],
            relation_type: params[:relation_type]
          }

          # Add delay if provided (only valid for precedes/follows)
          relation_data[:delay] = params[:delay] if params[:delay]

          response = redmine_client.post("/issues/#{issue_id}/relations", { relation: relation_data })
          response['relation'] || response
        end
      end
    end
  end
end
