# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/transports/stdio_transport'
require_relative '../../lib/mcp_protocol_adapter'
require_relative '../../lib/jsonrpc_handler'

RSpec.describe RedmineMcpServer::Transports::StdioTransport do
  let(:logger) { Logger.new(StringIO.new) }
  let(:mcp_server) { instance_double(RedmineMcpServer::McpServer) }
  let(:protocol_adapter) { RedmineMcpServer::McpProtocolAdapter.new(mcp_server, logger) }
  let(:transport) { described_class.new(protocol_adapter, logger) }

  describe '#initialize' do
    it 'sets up the transport with protocol adapter and logger' do
      expect(transport.instance_variable_get(:@protocol_adapter)).to eq(protocol_adapter)
      expect(transport.instance_variable_get(:@logger)).to eq(logger)
    end

    it 'enables sync mode on stdout and stderr' do
      expect($stdout.sync).to be true
      expect($stderr.sync).to be true
    end

    it 'initializes running state to false' do
      expect(transport.instance_variable_get(:@running)).to be false
    end
  end

  describe '#read_line' do
    it 'reads a line from stdin and strips whitespace' do
      allow($stdin).to receive(:gets).and_return("  test line  \n")
      line = transport.send(:read_line)
      expect(line).to eq('test line')
    end

    it 'returns nil on EOF' do
      allow($stdin).to receive(:gets).and_return(nil)
      line = transport.send(:read_line)
      expect(line).to be_nil
    end

    it 'returns nil for empty lines' do
      allow($stdin).to receive(:gets).and_return("  \n")
      line = transport.send(:read_line)
      expect(line).to be_nil
    end

    it 'handles IO errors gracefully' do
      allow($stdin).to receive(:gets).and_raise(IOError.new('test error'))
      line = transport.send(:read_line)
      expect(line).to be_nil
    end
  end

  describe '#write_response' do
    it 'writes JSON-RPC response to stdout with newline' do
      response = { jsonrpc: '2.0', id: 1, result: { test: 'data' } }
      expect($stdout).to receive(:puts).with(Oj.dump(response, mode: :compat))
      transport.send(:write_response, response)
    end

    it 'raises error if response contains embedded newlines' do
      # This shouldn't happen with Oj.dump, but test the validation
      response = { jsonrpc: '2.0', id: 1, result: { test: 'data' } }
      allow(Oj).to receive(:dump).and_return("test\nwith\nnewlines")

      expect do
        transport.send(:write_response, response)
      end.to raise_error('Response contains embedded newline')
    end
  end

  describe '#extract_id_from_line' do
    it 'extracts numeric id from JSON string' do
      line = '{"jsonrpc":"2.0","id":123,"method":"test"}'
      id = transport.send(:extract_id_from_line, line)
      expect(id).to eq(123)
    end

    it 'extracts string id from JSON string' do
      line = '{"jsonrpc":"2.0","id":"test-id","method":"test"}'
      id = transport.send(:extract_id_from_line, line)
      expect(id).to eq('test-id')
    end

    it 'returns nil if no id field present' do
      line = '{"jsonrpc":"2.0","method":"test"}'
      id = transport.send(:extract_id_from_line, line)
      expect(id).to be_nil
    end

    it 'returns nil if line does not contain id' do
      line = '{"jsonrpc":"2.0"}'
      id = transport.send(:extract_id_from_line, line)
      expect(id).to be_nil
    end
  end

  describe '#process_line' do
    let(:valid_request) { '{"jsonrpc":"2.0","method":"ping","id":1}' }

    before do
      # Mock the MCP server to avoid initialization requirement
      allow(mcp_server).to receive_messages(tools: [], resources: [])
    end

    it 'parses valid JSON-RPC and sends response' do
      expect(protocol_adapter).to receive(:handle_request).and_return(
        { jsonrpc: '2.0', id: 1, result: {} }
      )
      expect($stdout).to receive(:puts)
      transport.send(:process_line, valid_request)
    end

    it 'sends error response for parse errors' do
      invalid_json = '{"invalid json'
      expect($stdout).to receive(:puts) do |output|
        response = Oj.load(output)
        expect(response['error']['code']).to eq(RedmineMcpServer::JsonRpcHandler::PARSE_ERROR)
      end
      transport.send(:process_line, invalid_json)
    end

    it 'sends error response for JSON-RPC errors' do
      expect(protocol_adapter).to receive(:handle_request).and_raise(
        RedmineMcpServer::JsonRpcHandler::JsonRpcError.new(-32_601, 'Method not found')
      )
      expect($stdout).to receive(:puts) do |output|
        response = Oj.load(output)
        expect(response['error']['code']).to eq(-32_601)
      end
      transport.send(:process_line, valid_request)
    end

    it 'does not send response for notifications' do
      expect(protocol_adapter).to receive(:handle_request).and_return(nil)
      expect($stdout).not_to receive(:puts)
      notification = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
      transport.send(:process_line, notification)
    end
  end

  describe '#start' do
    it 'reads lines until stdin closes' do
      lines = ['{"jsonrpc":"2.0","method":"ping","id":1}', nil]
      allow($stdin).to receive(:gets).and_return(*lines)
      allow(protocol_adapter).to receive(:handle_request).and_return(
        { jsonrpc: '2.0', id: 1, result: {} }
      )
      allow($stdout).to receive(:puts)

      transport.start
    end

    it 'handles interrupt signal gracefully' do
      allow($stdin).to receive(:gets).and_raise(Interrupt)
      expect { transport.start }.not_to raise_error
    end

    it 'handles unexpected errors and re-raises' do
      allow($stdin).to receive(:gets).and_raise(StandardError.new('unexpected'))
      expect { transport.start }.to raise_error(StandardError, 'unexpected')
    end
  end

  describe '#stop' do
    it 'sets running state to false' do
      transport.instance_variable_set(:@running, true)
      transport.stop
      expect(transport.instance_variable_get(:@running)).to be false
    end
  end
end
