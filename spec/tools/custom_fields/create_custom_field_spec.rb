# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/custom_fields/create_custom_field'

RSpec.describe RedmineMcpServer::Tools::CustomFields::CreateCustomFieldTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_custom_field')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new custom field')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:field_format)
      expect(schema[:properties]).to have_key(:type)
      expect(schema[:required]).to include('name', 'field_format')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a custom field' do
        params = {
          name: 'Test Field',
          field_format: 'string'
        }

        response_body = {
          'id' => 10,
          'name' => 'Test Field',
          'type' => 'IssueCustomField',
          'field_format' => 'string',
          'is_required' => false,
          'is_for_all' => true
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .with(body: /Test Field/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(10)
        expect(result[:data]['name']).to eq('Test Field')
      end
    end

    context 'with list field and possible values' do
      it 'creates a list custom field' do
        params = {
          name: 'Status',
          field_format: 'list',
          type: 'ProjectCustomField',
          possible_values: %w[Active Inactive Archived]
        }

        response_body = {
          'id' => 11,
          'name' => 'Status',
          'type' => 'ProjectCustomField',
          'field_format' => 'list',
          'possible_values' => %w[Active Inactive Archived]
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['field_format']).to eq('list')
        expect(result[:data]['possible_values']).to eq(%w[Active Inactive Archived])
      end
    end

    context 'with validation rules' do
      it 'creates field with validators' do
        params = {
          name: 'Description',
          field_format: 'text',
          min_length: 10,
          max_length: 500,
          is_required: true,
          searchable: true
        }

        response_body = {
          'id' => 12,
          'name' => 'Description',
          'field_format' => 'text',
          'min_length' => 10,
          'max_length' => 500,
          'is_required' => true,
          'searchable' => true
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'with tracker_ids for issue custom field' do
      it 'creates field for specific trackers' do
        params = {
          name: 'Bug Priority',
          field_format: 'int',
          type: 'IssueCustomField',
          tracker_ids: [1, 2]
        }

        response_body = {
          'id' => 13,
          'name' => 'Bug Priority',
          'type' => 'IssueCustomField',
          'tracker_ids' => [1, 2]
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when name is missing' do
      it 'returns error response' do
        result = tool.call({ field_format: 'string' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: name')
      end
    end

    context 'when field_format is missing' do
      it 'returns error response' do
        result = tool.call({ name: 'Test Field' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: field_format')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          name: '',
          field_format: 'string'
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .to_return(status: 422, body: { 'errors' => ['Name cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden (not admin)' do
      it 'returns authorization error' do
        params = {
          name: 'Test Field',
          field_format: 'string'
        }

        stub_request(:post, "#{base_url}/extended_api/custom_fields.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
