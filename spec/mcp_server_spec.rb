# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'

RSpec.describe RedmineMcpServer::McpServer do
  include Rack::Test::Methods

  let(:mcp_server) { RedmineMcpServer.mcp_server }
  let(:app) { mcp_server.to_rack_app }

  describe 'Rack application' do
    it 'responds to requests' do
      expect(app).to respond_to(:call)
    end
  end

  describe 'GET /mcp/tools' do
    it 'returns list of available tools' do
      get '/mcp/tools'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['tools']).to be_an(Array)
      expect(body['tools']).not_to be_empty
    end

    it 'includes tool metadata' do
      get '/mcp/tools'

      body = JSON.parse(last_response.body)
      tool = body['tools'].first

      expect(tool).to have_key('name')
      expect(tool).to have_key('description')
      expect(tool).to have_key('inputSchema')
    end

    it 'includes all registered project tools' do
      get '/mcp/tools'

      body = JSON.parse(last_response.body)
      tool_names = body['tools'].map { |t| t['name'] }

      expect(tool_names).to include('list_projects')
      expect(tool_names).to include('get_project')
      expect(tool_names).to include('create_project')
      expect(tool_names).to include('update_project')
      expect(tool_names).to include('delete_project')
    end
  end

  describe 'POST /mcp/tools/call' do
    context 'with valid tool and parameters' do
      it 'executes the tool and returns result' do
        projects_data = {
          'projects' => [
            { 'id' => 1, 'name' => 'Project 1' }
          ],
          'total_count' => 1
        }

        stub_request(:get, %r{localhost:3000/projects.json})
          .to_return(status: 200, body: projects_data.to_json, headers: { 'Content-Type' => 'application/json' })

        post '/mcp/tools/call', { name: 'list_projects', params: {} }.to_json,
             { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body['success']).to be true
        expect(body['data']).to have_key('projects')
      end
    end

    context 'with missing tool parameter' do
      it 'returns error response' do
        post '/mcp/tools/call', { params: {} }.to_json,
             { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body['success']).to be false
        expect(body['error']['message']).to include('not found')
      end
    end

    context 'with unknown tool name' do
      it 'returns error response' do
        post '/mcp/tools/call', { name: 'nonexistent_tool', params: {} }.to_json,
             { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body['success']).to be false
        expect(body['error']['message']).to include('not found')
      end
    end

    context 'with invalid JSON body' do
      it 'returns error response' do
        post '/mcp/tools/call', 'invalid json',
             { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)

        expect(body['error']).to eq('Invalid JSON')
      end
    end

    context 'with tool execution error' do
      it 'returns error response with details' do
        post '/mcp/tools/call', { name: 'get_project', params: {} }.to_json,
             { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body['success']).to be false
        expect(body['error']).to have_key('message')
        expect(body['error']['message']).to include('Missing required parameters')
      end
    end
  end

  describe 'GET /mcp/resources' do
    it 'returns list of available resources' do
      get '/mcp/resources'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['resources']).to be_an(Array)
    end
  end

  describe 'GET /mcp/info' do
    it 'returns server information' do
      get '/mcp/info'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)

      expect(body).to have_key('name')
      expect(body).to have_key('version')
      expect(body).to have_key('description')
      expect(body).to have_key('capabilities')
    end
  end

  describe 'GET /' do
    it 'returns server status' do
      get '/'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['status']).to eq('ok')
    end
  end

  describe 'GET /health' do
    it 'returns health check' do
      get '/health'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)

      expect(body['status']).to eq('ok')
    end
  end

  describe 'unsupported endpoints' do
    it 'returns 404 for unknown routes' do
      get '/unknown/route'

      expect(last_response.status).to eq(404)
    end
  end
end
