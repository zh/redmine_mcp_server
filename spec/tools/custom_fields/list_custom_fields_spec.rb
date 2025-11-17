# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/custom_fields/list_custom_fields'

RSpec.describe RedmineMcpServer::Tools::CustomFields::ListCustomFieldsTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_custom_fields')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List all custom fields')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to be_a(Hash)
    end
  end

  describe '#call' do
    context 'listing all custom fields' do
      it 'retrieves all custom fields' do
        response_body = {
          'custom_fields' => [
            {
              'id' => 1,
              'name' => 'Project Type',
              'customized_type' => 'project',
              'field_format' => 'list',
              'possible_values' => %w[Internal External],
              'is_required' => false,
              'is_for_all' => true
            },
            {
              'id' => 2,
              'name' => 'Issue Priority',
              'customized_type' => 'issue',
              'field_format' => 'int',
              'is_required' => true,
              'is_for_all' => false
            },
            {
              'id' => 3,
              'name' => 'Start Date',
              'customized_type' => 'time_entry',
              'field_format' => 'date',
              'is_required' => false,
              'is_for_all' => true
            }
          ]
        }

        stub_request(:get, "#{base_url}/custom_fields.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:custom_fields].length).to eq(3)
        expect(result[:data][:custom_fields][0]['name']).to eq('Project Type')
        expect(result[:data][:custom_fields][1]['customized_type']).to eq('issue')
        expect(result[:data][:custom_fields][2]['field_format']).to eq('date')
      end
    end

    context 'when no custom fields exist' do
      it 'returns empty array' do
        response_body = {
          'custom_fields' => []
        }

        stub_request(:get, "#{base_url}/custom_fields.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:custom_fields]).to be_empty
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/custom_fields.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:get, "#{base_url}/custom_fields.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
