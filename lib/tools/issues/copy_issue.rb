# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      # Tool for copying an issue in Redmine (same or different project)
      class CopyIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'copy_issue'
        end

        def description
          'Copy an issue to the same or different project. Creates a new issue with the same attributes. ' \
          'Optionally creates a "copied_to/copied_from" relation to link the issues.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Source issue ID to copy from'
              },
              project_id: {
                type: %w[string integer],
                description: 'Target project ID or identifier (can be same as source)'
              },
              link: {
                type: 'boolean',
                description: 'Create "copied_to/copied_from" relation between issues (default: false)'
              },
              subject_prefix: {
                type: 'string',
                description: 'Prefix to add to copied issue subject (e.g., "Copy of ")'
              }
            },
            required: %w[id project_id]
          }
        end

        def execute(params)
          validate_required_params(params, :id, :project_id)

          source_id = params[:id]
          target_project_id = params[:project_id]

          # Fetch source issue with full details
          source_response = redmine_client.get("/issues/#{source_id}")
          source_issue = source_response['issue']

          raise ArgumentError, "Source issue '#{source_id}' not found" unless source_issue

          # Build new issue data from source
          issue_data = {
            project_id: target_project_id,
            tracker_id: source_issue['tracker']['id'],
            subject: build_subject(source_issue['subject'], params[:subject_prefix]),
            description: source_issue['description']
          }

          # Copy optional fields if present in source
          issue_data[:priority_id] = source_issue['priority']['id'] if source_issue['priority']
          issue_data[:assigned_to_id] = source_issue['assigned_to']['id'] if source_issue['assigned_to']
          issue_data[:category_id] = source_issue['category']['id'] if source_issue['category']
          issue_data[:fixed_version_id] = source_issue['fixed_version']['id'] if source_issue['fixed_version']
          issue_data[:parent_issue_id] = source_issue['parent']['id'] if source_issue['parent']
          issue_data[:estimated_hours] = source_issue['estimated_hours'] if source_issue['estimated_hours']
          issue_data[:done_ratio] = source_issue['done_ratio'] if source_issue['done_ratio']
          issue_data[:is_private] = source_issue['is_private'] if source_issue.key?('is_private')
          issue_data[:custom_fields] = source_issue['custom_fields'] if source_issue['custom_fields']

          # Create new issue
          response = redmine_client.post('/issues', { issue: issue_data })
          new_issue = response['issue'] || response

          # Create relation if requested
          if params[:link]
            begin
              redmine_client.post("/issues/#{source_id}/relations", {
                                    relation: {
                                      issue_to_id: new_issue['id'],
                                      relation_type: 'copied_to'
                                    }
                                  })
            rescue StandardError => e
              @logger.warn "Could not create relation: #{e.message}"
            end
          end

          # Return new issue with reference to source
          new_issue.merge('copied_from_issue_id' => source_id)
        end

        private

        def build_subject(original_subject, prefix)
          if prefix
            "#{prefix}#{original_subject}"
          else
            original_subject
          end
        end
      end
    end
  end
end
