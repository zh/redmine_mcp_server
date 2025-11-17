# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/projects/list_projects'

RSpec.describe RedmineMcpServer::Tools::Projects::ListProjectsTool do
  let(:redmine_client) { RedmineMcpServer.redmine_client }
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_projects')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List all accessible projects')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:limit)
      expect(schema[:properties]).to have_key(:offset)
      expect(schema[:properties]).to have_key(:include)
      expect(schema[:properties]).to have_key(:status)
    end
  end

  describe '#call' do
    context 'with default parameters' do
      it 'lists all projects' do
        response_body = {
          'projects' => [
            { 'id' => 1, 'name' => 'Project 1', 'identifier' => 'project-1' },
            { 'id' => 2, 'name' => 'Project 2', 'identifier' => 'project-2' }
          ],
          'total_count' => 2,
          'offset' => 0,
          'limit' => 25
        }

        stub_request(:get, "#{base_url}/projects.json")
          .with(headers: { 'X-Redmine-API-Key' => RedmineMcpServer.config[:redmine_api_key] })
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:projects]).to be_an(Array)
        expect(result[:data][:projects].size).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
      end
    end

    context 'with limit parameter' do
      it 'respects the limit parameter' do
        response_body = {
          'projects' => [{ 'id' => 1, 'name' => 'Project 1' }],
          'total_count' => 100,
          'offset' => 0,
          'limit' => 1
        }

        stub_request(:get, "#{base_url}/projects.json?limit=1")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ limit: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:projects].size).to eq(1)
      end
    end

    context 'with offset parameter' do
      it 'respects the offset parameter' do
        response_body = {
          'projects' => [{ 'id' => 11, 'name' => 'Project 11' }],
          'total_count' => 100,
          'offset' => 10,
          'limit' => 25
        }

        stub_request(:get, "#{base_url}/projects.json?offset=10")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ offset: 10 })

        expect(result[:success]).to be true
        expect(result[:data][:projects]).to be_an(Array)
      end
    end

    context 'with include parameter' do
      it 'includes related data' do
        response_body = {
          'projects' => [{
            'id' => 1,
            'name' => 'Project 1',
            'trackers' => [{ 'id' => 1, 'name' => 'Bug' }]
          }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/projects.json?include=trackers")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ include: 'trackers' })

        expect(result[:success]).to be true
        expect(result[:data][:projects].first).to have_key('trackers')
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        response_body = {
          'projects' => [{ 'id' => 1, 'name' => 'Active Project', 'status' => 1 }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/projects.json?status=1")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ status: 'active' })

        expect(result[:success]).to be true
        expect(result[:data][:projects]).to be_an(Array)
      end
    end

    context 'when API returns error' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/projects.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthenticationError')
      end
    end

    context 'when API returns empty list' do
      it 'returns empty projects array' do
        response_body = {
          'projects' => [],
          'total_count' => 0
        }

        stub_request(:get, "#{base_url}/projects.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:projects]).to eq([])
        expect(result[:data][:total_count]).to eq(0)
      end
    end
  end
end
