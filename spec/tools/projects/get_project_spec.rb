# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/projects/get_project'

RSpec.describe RedmineMcpServer::Tools::Projects::GetProjectTool do
  let(:redmine_client) { RedmineMcpServer.redmine_client }
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('get_project')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Get detailed information')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required id' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:id)
      expect(schema[:required]).to include('id')
    end
  end

  describe '#call' do
    context 'with valid project id' do
      it 'returns project details' do
        project_data = {
          'project' => {
            'id' => 1,
            'name' => 'Test Project',
            'identifier' => 'test-project',
            'description' => 'A test project',
            'status' => 1,
            'is_public' => true,
            'created_on' => '2024-01-01T00:00:00Z',
            'updated_on' => '2024-01-01T00:00:00Z'
          }
        }

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: project_data.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1 })

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
        expect(result[:data]['name']).to eq('Test Project')
        expect(result[:data]['identifier']).to eq('test-project')
      end
    end

    context 'with project identifier string' do
      it 'accepts identifier as string' do
        project_data = {
          'project' => {
            'id' => 1,
            'name' => 'Test Project',
            'identifier' => 'test-project'
          }
        }

        stub_request(:get, "#{base_url}/projects/test-project.json")
          .to_return(status: 200, body: project_data.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 'test-project' })

        expect(result[:success]).to be true
        expect(result[:data]['identifier']).to eq('test-project')
      end
    end

    context 'with include parameter' do
      it 'includes related data' do
        project_data = {
          'project' => {
            'id' => 1,
            'name' => 'Test Project',
            'trackers' => [
              { 'id' => 1, 'name' => 'Bug' },
              { 'id' => 2, 'name' => 'Feature' }
            ],
            'issue_categories' => [
              { 'id' => 1, 'name' => 'Backend' }
            ]
          }
        }

        stub_request(:get, "#{base_url}/projects/1.json?include=trackers%2Cissue_categories")
          .to_return(status: 200, body: project_data.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1, include: 'trackers,issue_categories' })

        expect(result[:success]).to be true
        expect(result[:data]['trackers']).to be_an(Array)
        expect(result[:data]['trackers'].size).to eq(2)
        expect(result[:data]['issue_categories']).to be_an(Array)
      end
    end

    context 'when project not found' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/projects/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('NotFoundError')
      end
    end

    context 'when id parameter is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthenticationError')
      end
    end
  end
end
