# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/custom_fields/delete_custom_field'

RSpec.describe RedmineMcpServer::Tools::CustomFields::DeleteCustomFieldTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('delete_custom_field')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Delete a custom field')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:custom_field_id)
      expect(schema[:required]).to include('custom_field_id')
    end
  end

  describe '#call' do
    context 'with valid custom_field_id' do
      it 'deletes the custom field' do
        stub_request(:delete, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 204, headers: {})

        result = tool.call({ custom_field_id: 10 })

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('deleted successfully')
      end
    end

    context 'when custom_field_id is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: custom_field_id')
      end
    end

    context 'when custom field not found' do
      it 'returns not found error' do
        stub_request(:delete, "#{base_url}/extended_api/custom_fields/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when custom field is in use' do
      it 'returns validation error' do
        stub_request(:delete, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 422, body: { 'errors' => ['Cannot delete custom field - it may be in use'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 10 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden (not admin)' do
      it 'returns authorization error' do
        stub_request(:delete, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 10 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:delete, "#{base_url}/extended_api/custom_fields/10.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ custom_field_id: 10 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
