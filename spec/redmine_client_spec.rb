# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedmineMcpServer::AsyncRedmineClient do
  let(:base_url) { 'http://redmine.example.com' }
  let(:api_key) { 'test_api_key_12345' }
  let(:client) { described_class.new(base_url, api_key, logger: Logger.new(nil)) }

  describe '#initialize' do
    it 'normalizes the base URL' do
      client = described_class.new('redmine.example.com', api_key, logger: Logger.new(nil))
      expect(client.base_url).to eq('http://redmine.example.com')
    end

    it 'removes trailing slash from URL' do
      client = described_class.new('http://redmine.example.com/', api_key, logger: Logger.new(nil))
      expect(client.base_url).to eq('http://redmine.example.com')
    end
  end

  describe '#get' do
    it 'performs GET request and returns parsed JSON' do
      stub_request(:get, "#{base_url}/projects.json")
        .with(headers: { 'X-Redmine-API-Key' => api_key })
        .to_return(status: 200, body: '{"projects":[{"id":1,"name":"Test"}]}', headers: { 'Content-Type' => 'application/json' })

      result = client.get('/projects')
      expect(result).to eq({ 'projects' => [{ 'id' => 1, 'name' => 'Test' }] })
    end

    it 'includes query parameters' do
      stub_request(:get, "#{base_url}/projects.json?status=active")
        .to_return(status: 200, body: '{"projects":[]}', headers: { 'Content-Type' => 'application/json' })

      client.get('/projects', { status: 'active' })
      expect(WebMock).to have_requested(:get, "#{base_url}/projects.json?status=active")
    end
  end

  describe '#post' do
    it 'performs POST request with JSON body' do
      stub_request(:post, "#{base_url}/projects.json")
        .with(
          body: '{"project":{"name":"New Project"}}',
          headers: { 'X-Redmine-API-Key' => api_key, 'Content-Type' => 'application/json' }
        )
        .to_return(status: 201, body: '{"project":{"id":1,"name":"New Project"}}', headers: { 'Content-Type' => 'application/json' })

      result = client.post('/projects', { project: { name: 'New Project' } })
      expect(result).to eq({ 'project' => { 'id' => 1, 'name' => 'New Project' } })
    end
  end

  describe '#put' do
    it 'performs PUT request with JSON body' do
      stub_request(:put, "#{base_url}/projects/1.json")
        .with(body: '{"project":{"name":"Updated"}}')
        .to_return(status: 200, body: '{"project":{"id":1,"name":"Updated"}}', headers: { 'Content-Type' => 'application/json' })

      result = client.put('/projects/1', { project: { name: 'Updated' } })
      expect(result).to eq({ 'project' => { 'id' => 1, 'name' => 'Updated' } })
    end
  end

  describe '#delete' do
    it 'performs DELETE request' do
      stub_request(:delete, "#{base_url}/projects/1.json")
        .to_return(status: 204)

      result = client.delete('/projects/1')
      expect(result).to eq({})
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/projects.json")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      expect { client.get('/projects') }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::AuthenticationError,
        'Invalid or missing API key'
      )
    end

    it 'raises AuthorizationError on 403' do
      stub_request(:get, "#{base_url}/projects.json")
        .to_return(status: 403)

      expect { client.get('/projects') }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::AuthorizationError,
        'Insufficient permissions'
      )
    end

    it 'raises NotFoundError on 404' do
      stub_request(:get, "#{base_url}/projects/999.json")
        .to_return(status: 404)

      expect { client.get('/projects/999') }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::NotFoundError,
        'Resource not found'
      )
    end

    it 'raises ValidationError on 422 with error details' do
      stub_request(:post, "#{base_url}/projects.json")
        .to_return(
          status: 422,
          body: '{"errors":["Name cannot be blank","Identifier is invalid"]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post('/projects', {}) }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::ValidationError,
        /Name cannot be blank, Identifier is invalid/
      )
    end

    it 'raises ServerError on 500' do
      stub_request(:get, "#{base_url}/projects.json")
        .to_return(status: 500)

      expect { client.get('/projects') }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::ServerError,
        'Server error (500)'
      )
    end
  end

  describe '#paginate' do
    it 'automatically paginates through all results' do
      stub_request(:get, "#{base_url}/projects.json?limit=2&offset=0")
        .to_return(
          status: 200,
          body: '{"projects":[{"id":1},{"id":2}],"total_count":5}',
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}/projects.json?limit=2&offset=2")
        .to_return(
          status: 200,
          body: '{"projects":[{"id":3},{"id":4}],"total_count":5}',
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{base_url}/projects.json?limit=2&offset=4")
        .to_return(
          status: 200,
          body: '{"projects":[{"id":5}],"total_count":5}',
          headers: { 'Content-Type' => 'application/json' }
        )

      results = client.paginate('/projects', {}, limit: 2)
      expect(results.map { |p| p['id'] }).to eq([1, 2, 3, 4, 5])
    end

    it 'supports block iteration' do
      stub_request(:get, "#{base_url}/projects.json?limit=10&offset=0")
        .to_return(
          status: 200,
          body: '{"projects":[{"id":1}],"total_count":1}',
          headers: { 'Content-Type' => 'application/json' }
        )

      collected = []
      client.paginate('/projects', {}, limit: 10) do |items, offset, total|
        collected << { items: items, offset: offset, total: total }
      end

      expect(collected.size).to eq(1)
      expect(collected[0][:items]).to eq([{ 'id' => 1 }])
      expect(collected[0][:total]).to eq(1)
    end
  end

  describe '#test_connection' do
    it 'returns true when connection is successful' do
      stub_request(:get, "#{base_url}/users/current.json")
        .to_return(
          status: 200,
          body: '{"user":{"id":1,"login":"admin"}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(client.test_connection).to be true
    end

    it 'raises error when connection fails' do
      stub_request(:get, "#{base_url}/users/current.json")
        .to_return(status: 401)

      expect { client.test_connection }.to raise_error(
        RedmineMcpServer::AsyncRedmineClient::AuthenticationError
      )
    end
  end
end
