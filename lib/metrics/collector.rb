# frozen_string_literal: true

require 'concurrent'

module RedmineMcpServer
  module Metrics
    # Thread-safe metrics collector for tracking MCP server performance
    class Collector
      attr_reader :tool_metrics, :api_metrics, :slow_requests

      def initialize
        @tool_metrics = Concurrent::Hash.new
        @api_metrics = Concurrent::Hash.new
        @slow_requests = Concurrent::Array.new
        @slow_threshold = ENV.fetch('METRICS_SLOW_THRESHOLD', '1.0').to_f
        @max_slow_requests = 100
        @start_time = Time.now
      end

      # Record tool execution
      def record_tool(tool_name, duration, success, error_type: nil)
        metrics = tool_metrics_for(tool_name)

        metrics[:total_calls].increment
        metrics[:total_duration].update do |v|
          v + duration
        end

        if success
          metrics[:success_count].increment
        else
          metrics[:error_count].increment
          error_metrics = metrics[:errors_by_type][error_type] ||= Concurrent::AtomicFixnum.new(0)
          error_metrics.increment
        end

        # Track slow requests
        return unless duration >= @slow_threshold

        add_slow_request(
          type: 'tool',
          name: tool_name,
          duration: duration,
          timestamp: Time.now,
          error: error_type
        )
      end

      # Record API call (internal Redmine API tracking)
      def record_api_call(endpoint, method, duration, status)
        key = "#{method.upcase} #{endpoint}"
        metrics = api_metrics_for(key)

        metrics[:total_calls].increment
        metrics[:total_duration].update do |v|
          v + duration
        end
        metrics[:status_counts][status] ||= Concurrent::AtomicFixnum.new(0)
        metrics[:status_counts][status].increment
      end

      # Get metrics summary for all tools
      def tool_summary
        tool_metrics.each_with_object([]) do |(tool_name, metrics), summary|
          total_calls = metrics[:total_calls].value
          next if total_calls.zero?

          total_duration = metrics[:total_duration].value

          summary << {
            tool: tool_name,
            total_calls: total_calls,
            success_count: metrics[:success_count].value,
            error_count: metrics[:error_count].value,
            total_duration_ms: (total_duration * 1000).round(2),
            avg_duration_ms: ((total_duration / total_calls) * 1000).round(2),
            errors_by_type: metrics[:errors_by_type].transform_values(&:value)
          }
        end
      end

      # Get metrics summary for API calls
      def api_summary
        api_metrics.each_with_object([]) do |(endpoint, metrics), summary|
          total_calls = metrics[:total_calls].value
          next if total_calls.zero?

          total_duration = metrics[:total_duration].value

          summary << {
            endpoint: endpoint,
            total_calls: total_calls,
            total_duration_ms: (total_duration * 1000).round(2),
            avg_duration_ms: ((total_duration / total_calls) * 1000).round(2),
            status_counts: metrics[:status_counts].transform_values(&:value)
          }
        end
      end

      # Get recent slow requests
      def slow_requests_summary
        slow_requests.to_a.map do |req|
          {
            type: req[:type],
            name: req[:name],
            duration_ms: (req[:duration] * 1000).round(2),
            timestamp: req[:timestamp].iso8601,
            error: req[:error]
          }
        end
      end

      # Get Prometheus-compatible metrics
      def prometheus_format
        lines = []

        # Tool metrics
        lines << '# HELP redmine_mcp_tool_calls_total Total number of tool calls'
        lines << '# TYPE redmine_mcp_tool_calls_total counter'
        tool_metrics.each do |tool_name, metrics|
          lines << "redmine_mcp_tool_calls_total{tool=\"#{tool_name}\"} #{metrics[:total_calls].value}"
        end

        lines << ''
        lines << '# HELP redmine_mcp_tool_duration_seconds Tool execution duration'
        lines << '# TYPE redmine_mcp_tool_duration_seconds summary'
        tool_metrics.each do |tool_name, metrics|
          total_calls = metrics[:total_calls].value
          next if total_calls.zero?

          avg_duration = metrics[:total_duration].value / total_calls
          lines << "redmine_mcp_tool_duration_seconds{tool=\"#{tool_name}\",quantile=\"0.5\"} #{avg_duration.round(3)}"
        end

        lines << ''
        lines << '# HELP redmine_mcp_tool_errors_total Total number of tool errors'
        lines << '# TYPE redmine_mcp_tool_errors_total counter'
        tool_metrics.each do |tool_name, metrics|
          lines << "redmine_mcp_tool_errors_total{tool=\"#{tool_name}\"} #{metrics[:error_count].value}"
        end

        lines << ''
        lines << '# HELP redmine_mcp_api_calls_total Total number of Redmine API calls'
        lines << '# TYPE redmine_mcp_api_calls_total counter'
        api_metrics.each do |endpoint, metrics|
          lines << "redmine_mcp_api_calls_total{endpoint=\"#{endpoint}\"} #{metrics[:total_calls].value}"
        end

        lines << ''
        lines << '# HELP redmine_mcp_uptime_seconds Server uptime in seconds'
        lines << '# TYPE redmine_mcp_uptime_seconds gauge'
        lines << "redmine_mcp_uptime_seconds #{(Time.now - @start_time).round(2)}"

        lines.join("\n")
      end

      # Reset all metrics (useful for testing)
      def reset!
        @tool_metrics = Concurrent::Hash.new
        @api_metrics = Concurrent::Hash.new
        @slow_requests = Concurrent::Array.new
        @start_time = Time.now
      end

      private

      def tool_metrics_for(tool_name)
        @tool_metrics[tool_name] ||= {
          total_calls: Concurrent::AtomicFixnum.new(0),
          success_count: Concurrent::AtomicFixnum.new(0),
          error_count: Concurrent::AtomicFixnum.new(0),
          total_duration: Concurrent::AtomicReference.new(0.0),
          errors_by_type: Concurrent::Hash.new
        }
      end

      def api_metrics_for(key)
        @api_metrics[key] ||= {
          total_calls: Concurrent::AtomicFixnum.new(0),
          total_duration: Concurrent::AtomicReference.new(0.0),
          status_counts: Concurrent::Hash.new
        }
      end

      def add_slow_request(req)
        @slow_requests.push(req)
        # Keep only last N slow requests
        @slow_requests.shift if @slow_requests.size > @max_slow_requests
      end
    end
  end
end
