# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      # Tool for moving an issue to a different project
      class MoveIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'move_issue'
        end

        def description
          'Move an issue to a different project. Changes the project_id of an existing issue. ' \
          'Optionally change the tracker if the current tracker is not available in the target project.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Issue ID to move'
              },
              project_id: {
                type: %w[string integer],
                description: 'Target project ID or identifier'
              },
              tracker_id: {
                type: 'integer',
                description: 'New tracker ID (if tracker not available in target project)'
              }
            },
            required: %w[id project_id]
          }
        end

        def execute(params)
          validate_required_params(params, :id, :project_id)

          issue_id = params[:id]
          issue_data = { project_id: params[:project_id] }

          # Add tracker change if specified
          issue_data[:tracker_id] = params[:tracker_id] if params[:tracker_id]

          # Update the issue
          response = redmine_client.put("/issues/#{issue_id}", { issue: issue_data })

          # Fetch updated issue if response is empty
          if response.empty?
            get_response = redmine_client.get("/issues/#{issue_id}")
            get_response['issue'] || get_response
          else
            response['issue'] || response
          end
        end
      end
    end
  end
end
