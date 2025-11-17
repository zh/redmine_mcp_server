# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer
  module Tools
    module Issues
      class DeleteIssueRelationTool < RedmineMcpServer::Tools::BaseTool
        def name = 'delete_issue_relation'
        def description = 'Delete an issue relation by relation ID'

        def input_schema
          { type: 'object', properties: { relation_id: { type: 'integer' } }, required: ['relation_id'] }
        end

        def execute(params)
          validate_required_params(params, :relation_id)

          relation_id = params[:relation_id]
          redmine_client.delete("/relations/#{relation_id}")

          {
            success: true,
            message: "Relation #{relation_id} has been deleted",
            deleted_relation_id: relation_id
          }
        end
      end
    end
  end
end
