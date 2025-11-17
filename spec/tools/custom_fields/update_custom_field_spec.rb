# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/custom_fields/update_custom_field'

RSpec.describe RedmineMcpServer::Tools::CustomFields::UpdateCustomFieldTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_custom_field')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing custom field')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:custom_field_id)
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:required]).to include('custom_field_id')
    end
  end

  describe '#call' do
    context 'updating name' do
      it 'updates the custom field name' do
        params = {
          custom_field_id: 10,
          name: 'Updated Field Name'
        }

        response_body = {
          'id' => 10,
          'name' => 'Updated Field Name',
          'field_format' => 'string'
        }

        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .with(body: /Updated Field Name/)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['name']).to eq('Updated Field Name')
      end
    end

    context 'updating validation rules' do
      it 'updates validators' do
        params = {
          custom_field_id: 10,
          is_required: true,
          min_length: 5,
          max_length: 100
        }

        response_body = {
          'id' => 10,
          'is_required' => true,
          'min_length' => 5,
          'max_length' => 100
        }

        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'updating possible values for list field' do
      it 'updates list options' do
        params = {
          custom_field_id: 10,
          possible_values: %w[New Modified Closed]
        }

        response_body = {
          'id' => 10,
          'field_format' => 'list',
          'possible_values' => %w[New Modified Closed]
        }

        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'updating tracker associations' do
      it 'updates tracker_ids' do
        params = {
          custom_field_id: 10,
          tracker_ids: [1, 2, 3]
        }

        response_body = {
          'id' => 10,
          'tracker_ids' => [1, 2, 3]
        }

        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when custom_field_id is missing' do
      it 'returns error response' do
        result = tool.call({ name: 'New Name' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: custom_field_id')
      end
    end

    context 'when custom field not found' do
      it 'returns not found error' do
        stub_request(:put, "#{base_url}/extended_api/custom_fields/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 999, name: 'New Name' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          custom_field_id: 10,
          name: ''
        }

        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 422, body: { 'errors' => ['Name cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden (not admin)' do
      it 'returns authorization error' do
        stub_request(:put, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 10, name: 'New Name' })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
