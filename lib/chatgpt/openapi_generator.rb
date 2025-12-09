# frozen_string_literal: true

require 'json'
require 'yaml'

module RedmineMcpServer
  module ChatGPT
    # Generates OpenAPI 3.1.0 schema from MCP tool definitions
    # Used by ChatGPT Actions to understand available API endpoints
    class OpenApiGenerator
      # Default set of tools to expose (OpenAI recommends minimal APIs)
      DEFAULT_TOOLS = %w[
        list_issues get_issue create_issue update_issue delete_issue
        list_projects get_project create_project
        list_time_entries get_time_entry create_time_entry
        list_users get_user
        list_versions get_version create_version
        list_memberships get_membership create_membership
        list_groups get_group
        list_queries
        list_custom_fields
        batch_execute
      ].freeze

      # Tool to REST mapping (for resource-based endpoints)
      TOOL_TO_REST = {
        'list_issues' => { method: 'get', path: '/issues', resource: 'issues' },
        'get_issue' => { method: 'get', path: '/issues/{id}', resource: 'issues' },
        'create_issue' => { method: 'post', path: '/issues', resource: 'issues' },
        'update_issue' => { method: 'put', path: '/issues/{id}', resource: 'issues' },
        'delete_issue' => { method: 'delete', path: '/issues/{id}', resource: 'issues' },

        'list_projects' => { method: 'get', path: '/projects', resource: 'projects' },
        'get_project' => { method: 'get', path: '/projects/{id}', resource: 'projects' },
        'create_project' => { method: 'post', path: '/projects', resource: 'projects' },
        'update_project' => { method: 'put', path: '/projects/{id}', resource: 'projects' },
        'delete_project' => { method: 'delete', path: '/projects/{id}', resource: 'projects' },

        'list_time_entries' => { method: 'get', path: '/time_entries', resource: 'time_entries' },
        'get_time_entry' => { method: 'get', path: '/time_entries/{id}', resource: 'time_entries' },
        'create_time_entry' => { method: 'post', path: '/time_entries', resource: 'time_entries' },
        'update_time_entry' => { method: 'put', path: '/time_entries/{id}', resource: 'time_entries' },
        'delete_time_entry' => { method: 'delete', path: '/time_entries/{id}', resource: 'time_entries' },

        'list_users' => { method: 'get', path: '/users', resource: 'users' },
        'get_user' => { method: 'get', path: '/users/{id}', resource: 'users' },

        'list_versions' => { method: 'get', path: '/versions', resource: 'versions' },
        'get_version' => { method: 'get', path: '/versions/{id}', resource: 'versions' },
        'create_version' => { method: 'post', path: '/versions', resource: 'versions' },
        'update_version' => { method: 'put', path: '/versions/{id}', resource: 'versions' },
        'delete_version' => { method: 'delete', path: '/versions/{id}', resource: 'versions' },

        'list_memberships' => { method: 'get', path: '/memberships', resource: 'memberships' },
        'get_membership' => { method: 'get', path: '/memberships/{id}', resource: 'memberships' },
        'create_membership' => { method: 'post', path: '/memberships', resource: 'memberships' },
        'delete_membership' => { method: 'delete', path: '/memberships/{id}', resource: 'memberships' },

        'list_groups' => { method: 'get', path: '/groups', resource: 'groups' },
        'get_group' => { method: 'get', path: '/groups/{id}', resource: 'groups' },

        'list_queries' => { method: 'get', path: '/queries', resource: 'queries' },
        'list_custom_fields' => { method: 'get', path: '/custom_fields', resource: 'custom_fields' }
      }.freeze

      def initialize(mcp_server, options = {})
        @mcp_server = mcp_server
        @server_url = options[:server_url] || ENV.fetch('OPENAPI_SERVER_URL', 'http://localhost:3100')
        @redmine_url = options[:redmine_url] || RedmineMcpServer.config[:redmine_url]
        @title = options[:title] || ENV.fetch('OPENAPI_TITLE', 'Redmine MCP API')
        @version = options[:version] || ENV.fetch('OPENAPI_VERSION', '1.0.0')
        @tools_filter = options[:tools] || DEFAULT_TOOLS
      end

      # Generate complete OpenAPI schema
      # @return [Hash] OpenAPI 3.1.0 schema
      def generate
        {
          'openapi' => '3.1.0',
          'info' => generate_info,
          'servers' => generate_servers,
          'security' => [{ 'oauth2' => %w[read write] }],
          'paths' => generate_paths,
          'components' => generate_components
        }
      end

      # Generate OpenAPI schema as JSON string
      # @return [String] JSON formatted schema
      def to_json(*_args)
        JSON.pretty_generate(generate)
      end

      # Generate OpenAPI schema as YAML string
      # @return [String] YAML formatted schema
      # rubocop:disable Rails/Delegate
      def to_yaml
        generate.to_yaml
      end
      # rubocop:enable Rails/Delegate

      private

      def generate_info
        {
          'title' => @title,
          'description' => 'Access Redmine project management features. ' \
                           'Manage issues, projects, time tracking, users, and more.',
          'version' => @version,
          'contact' => {
            'name' => 'Agileware',
            'url' => 'https://agileware.jp'
          }
        }
      end

      def generate_servers
        [
          {
            'url' => "#{@server_url}/api/v1",
            'description' => 'Redmine MCP API Server'
          }
        ]
      end

      def generate_paths
        paths = {}

        # Generate REST-style paths for mapped tools
        filtered_tools.each do |tool|
          mapping = TOOL_TO_REST[tool.name]
          if mapping
            add_rest_path(paths, tool, mapping)
          else
            # Add as generic tool endpoint
            add_generic_tool_path(paths, tool)
          end
        end

        paths
      end

      def add_rest_path(paths, tool, mapping)
        path = mapping[:path]
        method = mapping[:method]

        paths[path] ||= {}
        paths[path][method] = generate_operation(tool, mapping)
      end

      def add_generic_tool_path(paths, tool)
        path = "/tools/#{tool.name}"
        paths[path] ||= {}
        paths[path]['post'] = generate_generic_operation(tool)
      end

      def generate_operation(tool, mapping)
        operation = {
          'operationId' => tool.name,
          'summary' => tool.description.split('.').first,
          'description' => tool.description,
          'tags' => [mapping[:resource].capitalize],
          'responses' => generate_responses(tool)
        }

        # Add parameters for GET/DELETE, requestBody for POST/PUT
        schema = tool.input_schema
        properties = schema['properties'] || {}

        if %w[get delete].include?(mapping[:method])
          operation['parameters'] = generate_parameters(properties, mapping[:path])
        elsif %w[post put patch].include?(mapping[:method])
          # Some properties go in path/query, rest in body
          path_params = extract_path_params(mapping[:path])
          query_params = properties.slice(*path_params)
          body_params = properties.except(*path_params)

          operation['parameters'] = generate_parameters(query_params, mapping[:path]) if query_params.any?
          operation['requestBody'] = generate_request_body(body_params, schema['required'] || []) if body_params.any?
        end

        operation
      end

      def generate_generic_operation(tool)
        {
          'operationId' => tool.name,
          'summary' => tool.description.split('.').first,
          'description' => tool.description,
          'tags' => ['Tools'],
          'requestBody' => {
            'required' => true,
            'content' => {
              'application/json' => {
                'schema' => {
                  'type' => 'object',
                  'properties' => {
                    'arguments' => convert_schema(tool.input_schema)
                  }
                }
              }
            }
          },
          'responses' => generate_responses(tool)
        }
      end

      def generate_parameters(properties, path)
        path_params = extract_path_params(path)
        params = []

        properties.each do |name, prop|
          location = path_params.include?(name) ? 'path' : 'query'
          params << {
            'name' => name,
            'in' => location,
            'required' => path_params.include?(name),
            'description' => prop['description'] || "#{name} parameter",
            'schema' => convert_property_schema(prop)
          }
        end

        params
      end

      def extract_path_params(path)
        path.scan(/\{(\w+)\}/).flatten
      end

      def generate_request_body(properties, required)
        {
          'required' => true,
          'content' => {
            'application/json' => {
              'schema' => {
                'type' => 'object',
                'properties' => properties.transform_values { |v| convert_property_schema(v) },
                'required' => required & properties.keys
              }
            }
          }
        }
      end

      def generate_responses(_tool)
        {
          '200' => {
            'description' => 'Successful operation',
            'content' => {
              'application/json' => {
                'schema' => {
                  'type' => 'object'
                }
              }
            }
          },
          '400' => {
            'description' => 'Bad request',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/Error' }
              }
            }
          },
          '401' => {
            'description' => 'Unauthorized',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/Error' }
              }
            }
          },
          '404' => {
            'description' => 'Not found',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/Error' }
              }
            }
          },
          '500' => {
            'description' => 'Internal server error',
            'content' => {
              'application/json' => {
                'schema' => { '$ref' => '#/components/schemas/Error' }
              }
            }
          }
        }
      end

      def generate_components
        {
          'securitySchemes' => {
            'oauth2' => {
              'type' => 'oauth2',
              'flows' => {
                'authorizationCode' => {
                  'authorizationUrl' => "#{@redmine_url}/oauth/authorize",
                  'tokenUrl' => "#{@redmine_url}/oauth/token",
                  'scopes' => {
                    'read' => 'Read access to Redmine data',
                    'write' => 'Write access to Redmine data'
                  }
                }
              }
            }
          },
          'schemas' => {
            'Error' => {
              'type' => 'object',
              'properties' => {
                'error' => { 'type' => 'string' },
                'message' => { 'type' => 'string' },
                'status' => { 'type' => 'integer' }
              }
            }
          }
        }
      end

      def convert_schema(schema)
        result = {
          'type' => schema['type'] || 'object'
        }

        if schema['properties']
          result['properties'] = schema['properties'].transform_values { |v| convert_property_schema(v) }
        end

        result['required'] = schema['required'] if schema['required']
        result['description'] = schema['description'] if schema['description']

        result
      end

      def convert_property_schema(prop)
        result = {}

        # Handle type (could be string or array for nullable types)
        if prop['type'].is_a?(Array)
          # OpenAPI 3.1 supports type arrays, but ChatGPT might not
          # Use first non-null type
          result['type'] = prop['type'].find { |t| t != 'null' } || 'string'
          result['nullable'] = true if prop['type'].include?('null')
        else
          result['type'] = prop['type'] || 'string'
        end

        result['description'] = prop['description'] if prop['description']
        result['enum'] = prop['enum'] if prop['enum']
        result['default'] = prop['default'] if prop.key?('default')
        result['minimum'] = prop['minimum'] if prop['minimum']
        result['maximum'] = prop['maximum'] if prop['maximum']
        result['minLength'] = prop['minLength'] if prop['minLength']
        result['maxLength'] = prop['maxLength'] if prop['maxLength']
        result['pattern'] = prop['pattern'] if prop['pattern']
        result['format'] = prop['format'] if prop['format']

        # Handle items for arrays
        result['items'] = convert_property_schema(prop['items']) if prop['items']

        result
      end

      def filtered_tools
        @mcp_server.tools.select { |tool| @tools_filter.include?(tool.name) }
      end
    end
  end
end
