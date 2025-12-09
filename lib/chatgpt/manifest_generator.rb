# frozen_string_literal: true

require 'json'

module RedmineMcpServer
  module ChatGPT
    # Generates ai-plugin.json manifest for ChatGPT Actions/Plugins
    class ManifestGenerator
      def initialize(options = {})
        @server_url = options[:server_url] || ENV.fetch('OPENAPI_SERVER_URL', 'http://localhost:3100')
        @redmine_url = options[:redmine_url] || RedmineMcpServer.config[:redmine_url]
        @name_for_human = options[:name_for_human] || 'Redmine Project Manager'
        @name_for_model = options[:name_for_model] || 'redmine'
        @contact_email = options[:contact_email] || ENV.fetch('CONTACT_EMAIL', 'support@example.com')
        @legal_info_url = options[:legal_info_url] || ENV.fetch('LEGAL_INFO_URL', '')
      end

      # Generate the ai-plugin.json manifest
      # @return [Hash] Plugin manifest
      def generate
        {
          'schema_version' => 'v1',
          'name_for_human' => @name_for_human,
          'name_for_model' => @name_for_model,
          'description_for_human' => 'Manage Redmine projects, issues, time tracking, and more directly from ChatGPT.',
          'description_for_model' => description_for_model,
          'auth' => generate_auth,
          'api' => {
            'type' => 'openapi',
            'url' => "#{@server_url}/api/v1/openapi.json"
          },
          'logo_url' => "#{@server_url}/logo.png",
          'contact_email' => @contact_email,
          'legal_info_url' => @legal_info_url
        }
      end

      # Generate manifest as JSON string
      # @return [String] JSON formatted manifest
      def to_json(*_args)
        JSON.pretty_generate(generate)
      end

      private

      def generate_auth
        {
          'type' => 'oauth',
          'client_url' => "#{@redmine_url}/oauth/authorize",
          'scope' => 'read write',
          'authorization_url' => "#{@redmine_url}/oauth/token",
          'authorization_content_type' => 'application/x-www-form-urlencoded',
          'verification_tokens' => {
            'openai' => ENV.fetch('CHATGPT_VERIFICATION_TOKEN', 'REPLACE_WITH_YOUR_TOKEN')
          }
        }
      end

      def description_for_model
        <<~DESCRIPTION.strip
          Use this plugin to interact with Redmine project management system.

          Available capabilities:
          - List, view, create, and update issues (bugs, features, tasks)
          - List and view projects
          - Track time entries for work logging
          - View users and their assignments
          - View project versions/milestones
          - View project memberships and groups
          - Query saved filters

          When using this plugin:
          - Issue IDs and Project IDs are required integers for specific operations
          - Use list operations first to discover available IDs
          - Time entries require issue_id or project_id, plus hours and activity_id
          - Creating issues requires project_id, tracker_id, and subject at minimum

          The user is authenticated via OAuth with their own Redmine credentials,
          so all operations respect their permissions in the Redmine system.
        DESCRIPTION
      end
    end
  end
end
