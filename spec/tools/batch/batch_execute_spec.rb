# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/base_tool'
require_relative '../../../lib/tools/batch/batch_execute'

RSpec.describe RedmineMcpServer::Tools::Batch::BatchExecuteTool do
  let(:redmine_client) { instance_double(RedmineMcpServer::AsyncRedmineClient) }
  let(:tool) { described_class.new(redmine_client: redmine_client) }

  # Simple test tools
  class TestTool1 < RedmineMcpServer::Tools::BaseTool
    def name
      'test_tool_1'
    end

    def description
      'Test tool 1'
    end

    def input_schema
      { type: 'object', properties: {} }
    end

    def execute(params)
      { result: "tool1: #{params[:value]}" }
    end
  end

  class TestTool2 < RedmineMcpServer::Tools::BaseTool
    def name
      'test_tool_2'
    end

    def description
      'Test tool 2'
    end

    def input_schema
      { type: 'object', properties: {} }
    end

    def execute(params)
      { result: "tool2: #{params[:value]}" }
    end
  end

  class FailingTool < RedmineMcpServer::Tools::BaseTool
    def name
      'failing_tool'
    end

    def description
      'A tool that fails'
    end

    def input_schema
      { type: 'object', properties: {} }
    end

    def execute(_params)
      raise StandardError, 'Intentional failure'
    end
  end

  before do
    # Mock the MCP server with test tools
    mcp_server = instance_double(RedmineMcpServer::McpServer)
    allow(RedmineMcpServer).to receive(:mcp_server).and_return(mcp_server)

    test_tool_1 = TestTool1.new
    test_tool_2 = TestTool2.new
    failing_tool = FailingTool.new

    test_tools = [test_tool_1, test_tool_2, failing_tool]
    tools_hash = {
      'test_tool_1' => test_tool_1,
      'test_tool_2' => test_tool_2,
      'failing_tool' => failing_tool
    }

    allow(mcp_server).to receive_messages(tools: test_tools, tools_by_name: tools_hash)
  end

  describe '#name' do
    it 'returns correct name' do
      expect(tool.name).to eq('batch_execute')
    end
  end

  describe '#description' do
    it 'returns description' do
      expect(tool.description).to include('multiple MCP tools concurrently')
    end
  end

  describe '#input_schema' do
    it 'defines calls array as required' do
      schema = tool.input_schema
      expect(schema[:required]).to include('calls')
      expect(schema[:properties][:calls][:type]).to eq('array')
    end

    it 'defines optional max_concurrency' do
      schema = tool.input_schema
      expect(schema[:properties][:max_concurrency]).not_to be_nil
    end
  end

  describe '#execute' do
    context 'with valid calls' do
      it 'executes multiple tools successfully' do
        params = {
          calls: [
            { name: 'test_tool_1', params: { value: 'a' } },
            { name: 'test_tool_2', params: { value: 'b' } }
          ]
        }

        result = tool.execute(params)

        expect(result[:results].size).to eq(2)
        expect(result[:summary][:total]).to eq(2)
        expect(result[:summary][:successful]).to eq(2)
        expect(result[:summary][:failed]).to eq(0)

        expect(result[:results][0][:tool]).to eq('test_tool_1')
        expect(result[:results][0][:success]).to be true
        expect(result[:results][0][:data][:result]).to eq('tool1: a')

        expect(result[:results][1][:tool]).to eq('test_tool_2')
        expect(result[:results][1][:success]).to be true
        expect(result[:results][1][:data][:result]).to eq('tool2: b')
      end

      it 'includes duration for each call' do
        params = {
          calls: [
            { name: 'test_tool_1', params: {} }
          ]
        }

        result = tool.execute(params)

        expect(result[:results][0][:duration_ms]).to be_positive
      end
    end

    context 'with tool not found' do
      it 'returns error for unknown tool' do
        params = {
          calls: [
            { name: 'nonexistent_tool', params: {} }
          ]
        }

        result = tool.execute(params)

        expect(result[:summary][:failed]).to eq(1)
        expect(result[:results][0][:success]).to be false
        expect(result[:results][0][:error][:type]).to eq('ToolNotFoundError')
      end
    end

    context 'with failing tools' do
      it 'handles tool failures gracefully' do
        params = {
          calls: [
            { name: 'test_tool_1', params: { value: 'a' } },
            { name: 'failing_tool', params: {} },
            { name: 'test_tool_2', params: { value: 'b' } }
          ]
        }

        result = tool.execute(params)

        expect(result[:summary][:total]).to eq(3)
        expect(result[:summary][:successful]).to eq(2)
        expect(result[:summary][:failed]).to eq(1)

        # First tool succeeds
        expect(result[:results][0][:success]).to be true

        # Second tool fails
        expect(result[:results][1][:success]).to be false
        expect(result[:results][1][:error][:type]).to eq('Error')

        # Third tool still executes and succeeds
        expect(result[:results][2][:success]).to be true
      end
    end

    context 'with concurrency control' do
      it 'respects max_concurrency parameter' do
        params = {
          calls: 10.times.map { |i| { name: 'test_tool_1', params: { value: i } } },
          max_concurrency: 3
        }

        result = tool.execute(params)

        expect(result[:results].size).to eq(10)
        expect(result[:summary][:successful]).to eq(10)
      end

      it 'clamps max_concurrency to valid range' do
        # Should clamp to minimum 1
        params = {
          calls: [{ name: 'test_tool_1', params: {} }],
          max_concurrency: 0
        }

        result = tool.execute(params)
        expect(result[:results].size).to eq(1)

        # Should clamp to maximum 20
        params = {
          calls: [{ name: 'test_tool_1', params: {} }],
          max_concurrency: 50
        }

        result = tool.execute(params)
        expect(result[:results].size).to eq(1)
      end
    end

    context 'with empty calls array' do
      it 'returns empty results' do
        params = { calls: [] }

        result = tool.execute(params)

        expect(result[:results]).to be_empty
        expect(result[:summary][:total]).to eq(0)
      end
    end

    context 'with missing required parameter' do
      it 'raises ArgumentError' do
        expect { tool.execute({}) }.to raise_error(ArgumentError, /Missing required parameters: calls/)
      end
    end
  end

  describe 'concurrent execution' do
    it 'executes tools concurrently' do
      # Create a tool that sleeps to verify concurrency
      class SlowTool < RedmineMcpServer::Tools::BaseTool
        def name
          'slow_tool'
        end

        def description
          'A slow tool'
        end

        def input_schema
          { type: 'object', properties: {} }
        end

        def execute(_params)
          sleep 0.1
          { result: 'done' }
        end
      end

      mcp_server = RedmineMcpServer.mcp_server
      slow_tool = SlowTool.new
      allow(mcp_server).to receive_messages(tools: [slow_tool], tools_by_name: { slow_tool.name => slow_tool })

      params = {
        calls: 5.times.map { { name: 'slow_tool', params: {} } }
      }

      start_time = Time.now
      result = tool.execute(params)
      duration = Time.now - start_time

      # If executed serially, would take 0.5+ seconds
      # With concurrency, should be much faster (closer to 0.1-0.2 seconds)
      expect(result[:results].size).to eq(5)
      expect(duration).to be < 0.4 # Allow some margin for overhead
    end
  end
end
