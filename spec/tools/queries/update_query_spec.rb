# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/queries/update_query'

RSpec.describe RedmineMcpServer::Tools::Queries::UpdateQueryTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_query')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing query')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:query_id)
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:filters)
      expect(schema[:required]).to include('query_id')
    end
  end

  describe '#call' do
    context 'updating name' do
      it 'updates the query name' do
        params = {
          query_id: 10,
          name: 'Updated Query Name'
        }

        response_body = {
          'id' => 10,
          'name' => 'Updated Query Name',
          'type' => 'IssueQuery'
        }

        stub_request(:put, "#{base_url}/extended_api/queries/10.json")
          .with(body: /Updated Query Name/)
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['name']).to eq('Updated Query Name')
      end
    end

    context 'updating filters' do
      it 'updates query filters' do
        params = {
          query_id: 10,
          filters: {
            'assigned_to_id' => { 'operator' => '=', 'values' => ['me'] },
            'priority_id' => { 'operator' => '=', 'values' => %w[4 5] }
          }
        }

        response_body = {
          'id' => 10,
          'filters' => {
            'assigned_to_id' => { 'operator' => '=', 'values' => ['me'] },
            'priority_id' => { 'operator' => '=', 'values' => %w[4 5] }
          }
        }

        stub_request(:put, "#{base_url}/extended_api/queries/10.json")
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['filters']).to be_a(Hash)
      end
    end

    context 'updating description' do
      it 'updates query description' do
        params = {
          query_id: 10,
          description: 'Shows all overdue issues'
        }

        response_body = {
          'id' => 10,
          'description' => 'Shows all overdue issues'
        }

        stub_request(:put, "#{base_url}/extended_api/queries/10.json")
          .with(body: /Shows all overdue issues/)
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['description']).to eq('Shows all overdue issues')
      end
    end

    context 'when query not found' do
      it 'returns not found error' do
        stub_request(:put, "#{base_url}/extended_api/queries/999.json")
          .to_return(status: 404, body: { error: 'Not found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ query_id: 999, name: 'Test' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:put, "#{base_url}/extended_api/queries/10.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ query_id: 10, name: 'Test' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        stub_request(:put, "#{base_url}/extended_api/queries/10.json")
          .to_return(status: 422,
                     body: { 'errors' => ['Name cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ query_id: 10, name: '' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end
  end
end
