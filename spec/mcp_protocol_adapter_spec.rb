# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/mcp_protocol_adapter'
require_relative '../lib/jsonrpc_handler'

RSpec.describe RedmineMcpServer::McpProtocolAdapter do
  let(:logger) { Logger.new(StringIO.new) }
  let(:mcp_server) { instance_double(RedmineMcpServer::McpServer) }
  let(:adapter) { described_class.new(mcp_server, logger) }

  describe '#initialize' do
    it 'sets up the adapter with mcp_server and logger' do
      expect(adapter.instance_variable_get(:@mcp_server)).to eq(mcp_server)
      expect(adapter.instance_variable_get(:@logger)).to eq(logger)
    end

    it 'initializes state as not initialized' do
      expect(adapter.instance_variable_get(:@initialized)).to be false
      expect(adapter.instance_variable_get(:@client_info)).to be_nil
    end
  end

  describe '#handle_request' do
    context 'with notifications (no id)' do
      it 'returns nil for notifications/initialized' do
        message = { jsonrpc: '2.0', method: 'notifications/initialized', params: {} }
        result = adapter.handle_request(message)
        expect(result).to be_nil
        expect(adapter.instance_variable_get(:@initialized)).to be true
      end

      it 'returns nil for other notifications' do
        message = { jsonrpc: '2.0', method: 'notifications/cancelled', params: { requestId: '123' } }
        result = adapter.handle_request(message)
        expect(result).to be_nil
      end
    end

    context 'before initialization' do
      it 'allows initialize method' do
        message = {
          jsonrpc: '2.0',
          method: 'initialize',
          id: 1,
          params: {
            protocolVersion: '2025-06-18',
            capabilities: {},
            clientInfo: { name: 'Test', version: '1.0' }
          }
        }
        allow(mcp_server).to receive_messages(tools: [], resources: [])

        result = adapter.handle_request(message)
        expect(result[:result][:protocolVersion]).to eq('2025-06-18')
      end

      it 'allows ping method' do
        message = { jsonrpc: '2.0', method: 'ping', id: 1, params: {} }
        result = adapter.handle_request(message)
        expect(result[:result]).to eq({})
      end

      it 'rejects other methods before initialization' do
        message = { jsonrpc: '2.0', method: 'tools/list', id: 1, params: {} }
        expect do
          adapter.handle_request(message)
        end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
          expect(error.code).to eq(-32_002)
          expect(error.message).to eq('Not initialized')
        end
      end
    end

    context 'after initialization' do
      before do
        # Initialize the adapter
        adapter.instance_variable_set(:@initialized, true)
      end

      it 'returns JSON-RPC response with id and result' do
        message = { jsonrpc: '2.0', method: 'ping', id: 42, params: {} }
        result = adapter.handle_request(message)
        expect(result[:jsonrpc]).to eq('2.0')
        expect(result[:id]).to eq(42)
        expect(result[:result]).to be_a(Hash)
      end

      it 'wraps unexpected errors as internal errors' do
        message = { jsonrpc: '2.0', method: 'tools/list', id: 1, params: {} }
        allow(mcp_server).to receive(:list_tools).and_raise(StandardError.new('unexpected error'))

        expect do
          adapter.handle_request(message)
        end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
          expect(error.code).to eq(RedmineMcpServer::JsonRpcHandler::INTERNAL_ERROR)
          expect(error.message).to include('Internal error')
        end
      end
    end
  end

  describe '#handle_initialize' do
    let(:params) do
      {
        protocolVersion: '2025-06-18',
        capabilities: {},
        clientInfo: { name: 'Claude Desktop', version: '1.0.0' }
      }
    end

    before do
      allow(mcp_server).to receive_messages(tools: [], resources: [])
    end

    it 'returns server capabilities and info' do
      result = adapter.send(:handle_initialize, params)
      expect(result[:protocolVersion]).to eq('2025-06-18')
      expect(result[:serverInfo][:name]).to eq('Redmine MCP Server')
      expect(result[:serverInfo][:version]).to eq('0.1.0')
      expect(result[:capabilities]).to be_a(Hash)
    end

    it 'stores client info' do
      adapter.send(:handle_initialize, params)
      expect(adapter.instance_variable_get(:@client_info)).to eq(params[:clientInfo])
    end

    it 'handles version mismatch gracefully' do
      params[:protocolVersion] = '2024-01-01'
      expect { adapter.send(:handle_initialize, params) }.not_to raise_error
    end
  end

  describe '#build_capabilities' do
    it 'includes tools capability when tools are registered' do
      tool = instance_double('Tool', name: 'test_tool')
      allow(mcp_server).to receive_messages(tools: [tool], resources: [])

      capabilities = adapter.send(:build_capabilities)
      expect(capabilities[:tools]).to eq({})
    end

    it 'includes resources capability when resources are registered' do
      resource = instance_double('Resource', uri: 'test://resource')
      allow(mcp_server).to receive_messages(tools: [], resources: [resource])

      capabilities = adapter.send(:build_capabilities)
      expect(capabilities[:resources]).to eq(subscribe: false, listChanged: false)
    end

    it 'always includes logging capability' do
      allow(mcp_server).to receive_messages(tools: [], resources: [])

      capabilities = adapter.send(:build_capabilities)
      expect(capabilities[:logging]).to eq({})
    end
  end

  describe '#handle_ping' do
    it 'returns empty hash' do
      result = adapter.send(:handle_ping, {})
      expect(result).to eq({})
    end
  end

  describe '#handle_tools_list' do
    it 'returns list of tools' do
      tools = [{ name: 'tool1' }, { name: 'tool2' }]
      allow(mcp_server).to receive(:list_tools).and_return(tools)

      result = adapter.send(:handle_tools_list, {})
      expect(result[:tools]).to eq(tools)
    end
  end

  describe '#handle_tools_call' do
    let(:tool) { instance_double('Tool', name: 'test_tool') }

    before do
      allow(mcp_server).to receive_messages(tools: [tool], tools_by_name: { 'test_tool' => tool })
    end

    it 'raises error if name parameter is missing' do
      expect do
        adapter.send(:handle_tools_call, {})
      end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
        expect(error.code).to eq(RedmineMcpServer::JsonRpcHandler::INVALID_PARAMS)
        expect(error.message).to eq('Missing required parameter: name')
      end
    end

    it 'raises error if tool is not found' do
      expect do
        adapter.send(:handle_tools_call, { name: 'nonexistent' })
      end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
        expect(error.code).to eq(RedmineMcpServer::JsonRpcHandler::METHOD_NOT_FOUND)
        expect(error.message).to eq('Tool not found: nonexistent')
      end
    end

    it 'calls the tool with MCP format' do
      arguments = { param: 'value' }
      mcp_result = { content: [{ type: 'text', text: 'result' }], isError: false }
      allow(tool).to receive(:call_for_mcp).with(arguments).and_return(mcp_result)

      result = adapter.send(:handle_tools_call, { name: 'test_tool', arguments: arguments })
      expect(result).to eq(mcp_result)
    end

    it 'handles tools with no arguments' do
      mcp_result = { content: [{ type: 'text', text: 'result' }], isError: false }
      allow(tool).to receive(:call_for_mcp).with({}).and_return(mcp_result)

      result = adapter.send(:handle_tools_call, { name: 'test_tool' })
      expect(result).to eq(mcp_result)
    end
  end

  describe '#handle_resources_list' do
    it 'returns list of resources' do
      resources = [{ uri: 'test://resource1' }, { uri: 'test://resource2' }]
      allow(mcp_server).to receive(:list_resources).and_return(resources)

      result = adapter.send(:handle_resources_list, {})
      expect(result[:resources]).to eq(resources)
    end
  end

  describe '#handle_resources_read' do
    let(:resource) { instance_double('Resource', uri: 'test://resource') }

    before do
      allow(mcp_server).to receive_messages(resources: [resource], resources_by_uri: { 'test://resource' => resource })
    end

    it 'raises error if uri parameter is missing' do
      expect do
        adapter.send(:handle_resources_read, {})
      end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
        expect(error.code).to eq(RedmineMcpServer::JsonRpcHandler::INVALID_PARAMS)
        expect(error.message).to eq('Missing required parameter: uri')
      end
    end

    it 'raises error if resource is not found' do
      expect do
        adapter.send(:handle_resources_read, { uri: 'test://nonexistent' })
      end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
        expect(error.code).to eq(-32_002)
        expect(error.message).to eq('Resource not found: test://nonexistent')
      end
    end

    it 'reads the resource with MCP format' do
      mcp_result = {
        contents: [{ uri: 'test://resource', mimeType: 'text/plain', text: 'content' }]
      }
      allow(resource).to receive(:read_for_mcp).and_return(mcp_result)

      result = adapter.send(:handle_resources_read, { uri: 'test://resource' })
      expect(result).to eq(mcp_result)
    end
  end

  describe '#route_method' do
    it 'raises METHOD_NOT_FOUND for unknown methods' do
      expect do
        adapter.send(:route_method, 'unknown/method', {})
      end.to raise_error(RedmineMcpServer::JsonRpcHandler::JsonRpcError) do |error|
        expect(error.code).to eq(RedmineMcpServer::JsonRpcHandler::METHOD_NOT_FOUND)
        expect(error.message).to eq('Method not found: unknown/method')
      end
    end
  end
end
