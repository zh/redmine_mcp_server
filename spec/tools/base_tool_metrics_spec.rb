# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/tools/base_tool'
require_relative '../../lib/metrics/collector'

RSpec.describe RedmineMcpServer::Tools::BaseTool, 'metrics' do
  let(:collector) { RedmineMcpServer::Metrics::Collector.new }
  let(:redmine_client) { instance_double(RedmineMcpServer::AsyncRedmineClient) }

  # Test tool implementation
  class TestTool < RedmineMcpServer::Tools::BaseTool
    def name
      'test_tool'
    end

    def description
      'A test tool'
    end

    def input_schema
      { type: 'object', properties: {} }
    end

    def execute(_params)
      { result: 'success' }
    end
  end

  # Test tool that raises an error
  class FailingTool < RedmineMcpServer::Tools::BaseTool
    def name
      'failing_tool'
    end

    def description
      'A failing test tool'
    end

    def input_schema
      { type: 'object', properties: {} }
    end

    def execute(_params)
      raise StandardError, 'Intentional failure'
    end
  end

  describe 'metrics collection' do
    context 'with metrics collector' do
      let(:tool) { TestTool.new(redmine_client: redmine_client, metrics_collector: collector) }

      it 'records successful tool execution' do
        result = tool.call({})

        expect(result[:success]).to be true
        summary = collector.tool_summary
        expect(summary.size).to eq(1)
        expect(summary.first[:tool]).to eq('test_tool')
        expect(summary.first[:success_count]).to eq(1)
        expect(summary.first[:error_count]).to eq(0)
      end

      it 'records execution duration' do
        tool.call({})

        summary = collector.tool_summary
        expect(summary.first[:total_duration_ms]).to be_positive
        expect(summary.first[:avg_duration_ms]).to be_positive
      end

      it 'records multiple executions' do
        3.times do
          tool.call({})
        end

        summary = collector.tool_summary
        expect(summary.first[:total_calls]).to eq(3)
        expect(summary.first[:success_count]).to eq(3)
      end
    end

    context 'with failing tool' do
      let(:tool) { FailingTool.new(redmine_client: redmine_client, metrics_collector: collector) }

      it 'records failed execution' do
        result = tool.call({})

        expect(result[:success]).to be false
        summary = collector.tool_summary
        expect(summary.first[:error_count]).to eq(1)
        expect(summary.first[:errors_by_type]['Error']).to eq(1)
      end

      it 'still records duration for failures' do
        tool.call({})

        summary = collector.tool_summary
        expect(summary.first[:total_duration_ms]).to be_positive
      end
    end

    context 'with Redmine errors' do
      let(:tool) { TestTool.new(redmine_client: redmine_client, metrics_collector: collector) }

      before do
        allow_any_instance_of(TestTool).to receive(:execute).and_raise(
          RedmineMcpServer::AsyncRedmineClient::AuthenticationError.new(
            'Invalid API key',
            status: 401,
            response_body: {}
          )
        )
      end

      it 'records Redmine error types' do
        result = tool.call({})

        expect(result[:success]).to be false
        summary = collector.tool_summary
        expect(summary.first[:errors_by_type]['AuthenticationError']).to eq(1)
      end
    end

    context 'without metrics collector' do
      let(:tool) { TestTool.new(redmine_client: redmine_client) }

      it 'works normally without collector' do
        result = tool.call({})

        expect(result[:success]).to be true
        # No metrics should be recorded
        expect(collector.tool_summary).to be_empty
      end
    end
  end

  describe 'slow request tracking' do
    let(:tool) { TestTool.new(redmine_client: redmine_client, metrics_collector: collector) }

    before do
      allow_any_instance_of(TestTool).to receive(:execute) do
        sleep 1.1 # Exceed default slow threshold of 1.0 second
        { result: 'slow' }
      end
    end

    it 'tracks slow tool executions' do
      tool.call({})

      slow = collector.slow_requests_summary
      expect(slow.size).to eq(1)
      expect(slow.first[:type]).to eq('tool')
      expect(slow.first[:name]).to eq('test_tool')
      expect(slow.first[:duration_ms]).to be > 1000
    end
  end
end
