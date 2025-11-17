# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/projects/create_project'

RSpec.describe RedmineMcpServer::Tools::Projects::CreateProjectTool do
  let(:redmine_client) { RedmineMcpServer.redmine_client }
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_project')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new project')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:identifier)
      expect(schema[:required]).to include('name', 'identifier')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a new project' do
        params = {
          name: 'New Project',
          identifier: 'new-project'
        }

        response_body = {
          'project' => {
            'id' => 100,
            'name' => 'New Project',
            'identifier' => 'new-project',
            'status' => 1,
            'is_public' => true,
            'created_on' => '2024-01-01T00:00:00Z'
          }
        }

        stub_request(:post, "#{base_url}/projects.json")
          .with(
            body: /New Project.*new-project/
          )
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['name']).to eq('New Project')
        expect(result[:data]['identifier']).to eq('new-project')
      end
    end

    context 'with all optional parameters' do
      it 'creates project with all fields' do
        params = {
          name: 'Complete Project',
          identifier: 'complete-project',
          description: 'A complete project description',
          homepage: 'https://example.com',
          is_public: false,
          parent_id: 1,
          inherit_members: true,
          enabled_module_names: %w[issue_tracking time_tracking],
          tracker_ids: [1, 2, 3],
          custom_fields: [
            { id: 1, value: 'Custom Value' }
          ]
        }

        response_body = {
          'project' => {
            'id' => 101,
            'name' => 'Complete Project',
            'identifier' => 'complete-project',
            'description' => 'A complete project description',
            'homepage' => 'https://example.com',
            'is_public' => false,
            'parent' => { 'id' => 1, 'name' => 'Parent Project' }
          }
        }

        stub_request(:post, "#{base_url}/projects.json")
          .with(
            body: /Complete Project.*complete-project/
          )
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(101)
        expect(result[:data]['description']).to eq('A complete project description')
        expect(result[:data]['is_public']).to be false
      end
    end

    context 'when name is missing' do
      it 'returns error response' do
        result = tool.call({ identifier: 'test' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: name')
      end
    end

    context 'when identifier is missing' do
      it 'returns error response' do
        result = tool.call({ name: 'Test Project' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: identifier')
      end
    end

    context 'when identifier is invalid' do
      it 'returns validation error' do
        params = {
          name: 'Test Project',
          identifier: 'Invalid Identifier!'
        }

        error_response = {
          'errors' => ['Identifier is invalid']
        }

        stub_request(:post, "#{base_url}/projects.json")
          .to_return(status: 422, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('ValidationError')
      end
    end

    context 'when identifier already exists' do
      it 'returns validation error' do
        params = {
          name: 'Duplicate Project',
          identifier: 'existing-project'
        }

        error_response = {
          'errors' => ['Identifier has already been taken']
        }

        stub_request(:post, "#{base_url}/projects.json")
          .to_return(status: 422, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          name: 'Test Project',
          identifier: 'test-project'
        }

        stub_request(:post, "#{base_url}/projects.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          name: 'Test Project',
          identifier: 'test-project'
        }

        stub_request(:post, "#{base_url}/projects.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthorizationError')
      end
    end
  end
end
