# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/groups/update_group'

RSpec.describe RedmineMcpServer::Tools::Groups::UpdateGroupTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_group')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing group')
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
    context 'with name update' do
      it 'updates group name' do
        params = {
          id: 1,
          name: 'Updated Name'
        }

        stub_request(:put, "#{base_url}/groups/1.json")
          .with(body: /Updated Name/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/groups/1.json")
          .to_return(status: 200, body: {
            'group' => { 'id' => 1, 'name' => 'Updated Name' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
        expect(result[:data]['name']).to eq('Updated Name')
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

    context 'when group not found' do
      it 'returns error response' do
        params = {
          id: 999,
          name: 'Updated'
        }

        stub_request(:put, "#{base_url}/groups/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          id: 1,
          name: ''
        }

        stub_request(:put, "#{base_url}/groups/1.json")
          .with(body: /name/)
          .to_return(status: 422, body: { 'errors' => ['Name cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          id: 1,
          name: 'Updated'
        }

        stub_request(:put, "#{base_url}/groups/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          id: 1,
          name: 'Updated'
        }

        stub_request(:put, "#{base_url}/groups/1.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
