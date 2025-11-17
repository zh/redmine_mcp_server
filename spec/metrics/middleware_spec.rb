# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../lib/metrics/collector'
require_relative '../../lib/metrics/middleware'

RSpec.describe RedmineMcpServer::Metrics::Middleware do
  include Rack::Test::Methods

  let(:collector) { RedmineMcpServer::Metrics::Collector.new }
  let(:inner_app) do
    lambda do |env|
      request = Rack::Request.new(env)
      raise StandardError, 'Test error' if request.path == '/error'

      [200, { 'Content-Type' => 'text/plain' }, ['OK']]
    end
  end
  let(:app) { described_class.new(inner_app, collector) }

  describe 'request tracking' do
    it 'records successful requests' do
      get '/'

      expect(last_response.status).to eq(200)
      summary = collector.api_summary
      expect(summary.size).to eq(1)
      expect(summary.first[:endpoint]).to eq('GET /')
      expect(summary.first[:status_counts][200]).to eq(1)
    end

    it 'records request duration' do
      get '/'

      summary = collector.api_summary
      expect(summary.first[:total_duration_ms]).to be >= 0
      expect(summary.first[:avg_duration_ms]).to be >= 0
    end

    it 'normalizes paths with IDs' do
      get '/projects/123'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('GET /projects/:id')
    end

    it 'removes query strings from paths' do
      get '/projects?limit=10'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('GET /projects')
    end

    it 'records error responses' do
      expect { get '/error' }.to raise_error(StandardError)

      summary = collector.api_summary
      expect(summary.first[:status_counts][500]).to eq(1)
    end
  end

  describe 'different HTTP methods' do
    it 'tracks GET requests' do
      get '/test'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('GET /test')
    end

    it 'tracks POST requests' do
      post '/test'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('POST /test')
    end

    it 'tracks PUT requests' do
      put '/test'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('PUT /test')
    end

    it 'tracks DELETE requests' do
      delete '/test'

      summary = collector.api_summary
      expect(summary.first[:endpoint]).to eq('DELETE /test')
    end
  end

  describe 'multiple requests' do
    it 'aggregates metrics correctly' do
      3.times do
        get '/test'
      end

      summary = collector.api_summary
      expect(summary.first[:total_calls]).to eq(3)
    end

    it 'tracks different endpoints separately' do
      get '/test1'
      get '/test2'

      summary = collector.api_summary
      expect(summary.size).to eq(2)
      expect(summary.map { |s| s[:endpoint] }).to contain_exactly('GET /test1', 'GET /test2')
    end
  end
end
