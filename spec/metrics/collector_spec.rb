# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/metrics/collector'

RSpec.describe RedmineMcpServer::Metrics::Collector do
  let(:collector) { described_class.new }

  describe '#initialize' do
    it 'initializes with empty metrics' do
      expect(collector.tool_metrics).to be_empty
      expect(collector.api_metrics).to be_empty
      expect(collector.slow_requests).to be_empty
    end
  end

  describe '#record_tool' do
    it 'records successful tool execution' do
      collector.record_tool('test_tool', 0.5, true)

      summary = collector.tool_summary
      expect(summary.size).to eq(1)
      expect(summary.first[:tool]).to eq('test_tool')
      expect(summary.first[:total_calls]).to eq(1)
      expect(summary.first[:success_count]).to eq(1)
      expect(summary.first[:error_count]).to eq(0)
    end

    it 'records failed tool execution' do
      collector.record_tool('test_tool', 0.5, false, error_type: 'ValidationError')

      summary = collector.tool_summary
      expect(summary.first[:error_count]).to eq(1)
      expect(summary.first[:errors_by_type]['ValidationError']).to eq(1)
    end

    it 'tracks slow requests' do
      collector.record_tool('slow_tool', 1.5, true)

      slow = collector.slow_requests_summary
      expect(slow.size).to eq(1)
      expect(slow.first[:type]).to eq('tool')
      expect(slow.first[:name]).to eq('slow_tool')
      expect(slow.first[:duration_ms]).to be > 1000
    end

    it 'calculates average duration correctly' do
      collector.record_tool('test_tool', 0.2, true)
      collector.record_tool('test_tool', 0.4, true)

      summary = collector.tool_summary
      expect(summary.first[:avg_duration_ms]).to eq(300.0) # (200 + 400) / 2
    end
  end

  describe '#record_api_call' do
    it 'records API call metrics' do
      collector.record_api_call('/projects', 'GET', 0.3, 200)

      summary = collector.api_summary
      expect(summary.size).to eq(1)
      expect(summary.first[:endpoint]).to eq('GET /projects')
      expect(summary.first[:total_calls]).to eq(1)
      expect(summary.first[:status_counts][200]).to eq(1)
    end

    it 'tracks different HTTP methods separately' do
      collector.record_api_call('/projects', 'GET', 0.3, 200)
      collector.record_api_call('/projects', 'POST', 0.5, 201)

      summary = collector.api_summary
      expect(summary.size).to eq(2)
      expect(summary.map { |s| s[:endpoint] }).to contain_exactly('GET /projects', 'POST /projects')
    end
  end

  describe '#prometheus_format' do
    it 'generates Prometheus-compatible format' do
      collector.record_tool('test_tool', 0.5, true)

      output = collector.prometheus_format
      expect(output).to include('# HELP redmine_mcp_tool_calls_total')
      expect(output).to include('# TYPE redmine_mcp_tool_calls_total counter')
      expect(output).to include('redmine_mcp_tool_calls_total{tool="test_tool"} 1')
    end

    it 'includes uptime metric' do
      output = collector.prometheus_format
      expect(output).to include('# HELP redmine_mcp_uptime_seconds')
      expect(output).to include('# TYPE redmine_mcp_uptime_seconds gauge')
      expect(output).to match(/redmine_mcp_uptime_seconds \d+\.\d+/)
    end
  end

  describe '#reset!' do
    it 'clears all metrics' do
      collector.record_tool('test_tool', 0.5, true)
      collector.record_api_call('/projects', 'GET', 0.3, 200)

      collector.reset!

      expect(collector.tool_metrics).to be_empty
      expect(collector.api_metrics).to be_empty
      expect(collector.slow_requests).to be_empty
    end
  end

  describe 'thread safety' do
    it 'handles concurrent tool recordings' do
      threads = 10.times.map { |i|
        Thread.new do
          10.times do
            collector.record_tool("tool_#{i}", 0.1, true)
          end
        end
      }

      threads.each(&:join)

      summary = collector.tool_summary
      expect(summary.size).to eq(10)
      summary.each do |s|
        expect(s[:total_calls]).to eq(10)
      end
    end
  end
end
