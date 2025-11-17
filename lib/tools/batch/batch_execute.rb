# frozen_string_literal: true

require 'async'

module RedmineMcpServer
  module Tools
    module Batch
      # Tool for executing multiple tools concurrently
      class BatchExecuteTool < BaseTool
        def name
          'batch_execute'
        end

        def description
          'Execute multiple MCP tools concurrently for improved performance. ' \
            'Returns results for all tool calls, handling partial failures gracefully.'
        end

        def input_schema
          {
            type: 'object',
            required: %w[calls],
            properties: {
              calls: {
                type: 'array',
                description: 'Array of tool calls to execute concurrently',
                items: {
                  type: 'object',
                  required: %w[name],
                  properties: {
                    name: {
                      type: 'string',
                      description: 'Name of the tool to call'
                    },
                    params: {
                      type: 'object',
                      description: 'Parameters for the tool call'
                    }
                  }
                }
              },
              max_concurrency: {
                type: 'integer',
                description: 'Maximum number of concurrent executions (default: 5)',
                minimum: 1,
                maximum: 20
              }
            }
          }
        end

        def execute(params)
          validate_required_params(params, :calls)

          calls = params[:calls]
          max_concurrency = params[:max_concurrency]&.to_i || 5
          [[max_concurrency, 1].max, 5].min # Clamp between 1 and 5

          # Get all available tools from the MCP server
          mcp_server = RedmineMcpServer.mcp_server
          tool_map = mcp_server.tools_by_name # Use O(1) hash lookup

          # Execute calls concurrently using async fibers
          results = Async do |task|
            # Create async tasks for each call
            tasks = calls.map do |call|
              task.async do
                execute_single_call(call, tool_map)
              end
            end

            # Wait for all tasks to complete
            tasks.map(&:wait)
          end.wait

          # Calculate summary statistics
          successful = results.count { |r| r[:success] }
          failed = results.count { |r| !r[:success] }

          {
            results: results,
            summary: {
              total: results.size,
              successful: successful,
              failed: failed
            }
          }
        end

        private

        def execute_single_call(call, tool_map)
          tool_name = call['name'] || call[:name]
          params = call['params'] || call[:params] || {}

          tool = tool_map[tool_name]

          unless tool
            return {
              tool: tool_name,
              success: false,
              error: {
                type: 'ToolNotFoundError',
                message: "Tool '#{tool_name}' not found"
              }
            }
          end

          # Execute the tool
          start_time = Time.now
          result = tool.call(params)
          duration = Time.now - start_time

          {
            tool: tool_name,
            success: result[:success],
            data: result[:data],
            error: result[:error],
            duration_ms: (duration * 1000).round(2)
          }
        rescue StandardError => e
          {
            tool: tool_name,
            success: false,
            error: {
              type: 'Error',
              message: e.message
            }
          }
        end
      end
    end
  end
end
