# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Memberships
      # Tool for getting a specific membership from Redmine
      class GetMembershipTool < BaseTool
        def name
          'get_membership'
        end

        def description
          'Get details of a specific project membership including user/group information and assigned roles.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              membership_id: {
                type: 'integer',
                description: 'Membership ID to retrieve (required)'
              }
            },
            required: %w[membership_id]
          }
        end

        def execute(params)
          validate_required_params(params, :membership_id)

          # Fetch membership
          response = redmine_client.get("/memberships/#{params[:membership_id]}")

          response['membership'] || response
        end
      end
    end
  end
end
