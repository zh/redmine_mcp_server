# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/projects/update_project'

RSpec.describe RedmineMcpServer::Tools::Projects::UpdateProjectTool do
  let(:redmine_client) { RedmineMcpServer.redmine_client }
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_project')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing project')
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
    context 'with single field update' do
      it 'updates project name' do
        params = {
          id: 1,
          name: 'Updated Project Name'
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /Updated Project Name/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 1, 'name' => 'Updated Project Name' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
        expect(result[:data]['name']).to eq('Updated Project Name')
      end
    end

    context 'with multiple field updates' do
      it 'updates multiple fields' do
        params = {
          id: 1,
          name: 'New Name',
          description: 'New Description',
          homepage: 'https://new-homepage.com',
          is_public: false
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /New Name/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 1, 'name' => 'New Name', 'description' => 'New Description' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
        expect(result[:data]['name']).to eq('New Name')
      end
    end

    context 'with identifier as string' do
      it 'accepts project identifier' do
        params = {
          id: 'test-project',
          name: 'Updated Name'
        }

        stub_request(:put, "#{base_url}/projects/test-project.json")
          .with(body: /Updated Name/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/test-project.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 'test-project', 'name' => 'Updated Name' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq('test-project')
        expect(result[:data]['name']).to eq('Updated Name')
      end
    end

    context 'with enabled modules update' do
      it 'updates enabled modules' do
        params = {
          id: 1,
          enabled_module_names: %w[issue_tracking time_tracking wiki]
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /enabled_module_names/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 1, 'name' => 'Project with modules' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'with tracker updates' do
      it 'updates tracker IDs' do
        params = {
          id: 1,
          tracker_ids: [1, 2, 3]
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /tracker_ids/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 1, 'name' => 'Project with trackers' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'with custom fields update' do
      it 'updates custom field values' do
        params = {
          id: 1,
          custom_fields: [
            { id: 1, value: 'Custom Value 1' },
            { id: 2, value: 'Custom Value 2' }
          ]
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /custom_fields/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/projects/1.json")
          .to_return(status: 200, body: {
            'project' => { 'id' => 1, 'name' => 'Project with custom fields' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({ name: 'New Name' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when no fields provided for update' do
      it 'returns error response' do
        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('At least one field must be provided')
      end
    end

    context 'when project not found' do
      it 'returns error response' do
        params = {
          id: 999,
          name: 'Updated Name'
        }

        stub_request(:put, "#{base_url}/projects/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('NotFoundError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          id: 1,
          name: ''
        }

        error_response = {
          'errors' => ['Name cannot be blank']
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .with(body: /name/)
          .to_return(status: 422, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          id: 1,
          name: 'Updated Name'
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          id: 1,
          name: 'Updated Name'
        }

        stub_request(:put, "#{base_url}/projects/1.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to include('AuthorizationError')
      end
    end
  end
end
