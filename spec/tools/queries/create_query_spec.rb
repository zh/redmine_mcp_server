# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/queries/create_query'

RSpec.describe RedmineMcpServer::Tools::Queries::CreateQueryTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_query')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new query')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:filters)
      expect(schema[:properties]).to have_key(:visibility)
      expect(schema[:required]).to include('name')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a private query' do
        params = {
          name: 'My Issues'
        }

        response_body = {
          'id' => 10,
          'name' => 'My Issues',
          'type' => 'IssueQuery',
          'visibility' => 0,
          'is_public' => false
        }

        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .with(body: /My Issues/)
          .to_return(status: 201, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(10)
        expect(result[:data]['name']).to eq('My Issues')
        expect(result[:data]['visibility']).to eq(0)
      end
    end

    context 'with filters' do
      it 'creates a query with filters' do
        params = {
          name: 'Late Issues',
          filters: {
            'due_date' => { 'operator' => '<=', 'values' => ['2025-05-01'] },
            'status_id' => { 'operator' => 'o', 'values' => [] }
          }
        }

        response_body = {
          'id' => 11,
          'name' => 'Late Issues',
          'type' => 'IssueQuery',
          'filters' => {
            'due_date' => { 'operator' => '<=', 'values' => ['2025-05-01'] },
            'status_id' => { 'operator' => 'o' }
          }
        }

        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .with(body: /Late Issues/)
          .to_return(status: 201, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['name']).to eq('Late Issues')
        expect(result[:data]['filters']).to be_a(Hash)
      end
    end

    context 'with project and public visibility' do
      it 'creates a public project query' do
        params = {
          name: 'Team Issues',
          project_id: 5,
          visibility: 2,
          column_names: %w[id subject status assigned_to due_date]
        }

        response_body = {
          'id' => 12,
          'name' => 'Team Issues',
          'type' => 'IssueQuery',
          'project_id' => 5,
          'visibility' => 2,
          'is_public' => true,
          'column_names' => %w[id subject status assigned_to due_date]
        }

        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .with(body: /Team Issues/)
          .to_return(status: 201, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['project_id']).to eq(5)
        expect(result[:data]['visibility']).to eq(2)
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = { name: '' }

        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .to_return(status: 422,
                     body: { 'errors' => ['Name cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ name: 'Test' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:post, "#{base_url}/extended_api/queries.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ name: 'Test', visibility: 2 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
