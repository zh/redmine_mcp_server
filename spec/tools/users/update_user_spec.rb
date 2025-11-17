# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/users/update_user'

RSpec.describe RedmineMcpServer::Tools::Users::UpdateUserTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_user')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing user')
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
      it 'updates user firstname' do
        params = {
          id: 1,
          firstname: 'Updated'
        }

        stub_request(:put, "#{base_url}/users/1.json")
          .with(body: /Updated/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/users/1.json")
          .to_return(status: 200, body: {
            'user' => { 'id' => 1, 'firstname' => 'Updated' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
        expect(result[:data]['firstname']).to eq('Updated')
      end
    end

    context 'with multiple field updates' do
      it 'updates multiple fields' do
        params = {
          id: 1,
          firstname: 'New',
          lastname: 'Name',
          mail: 'new@example.com'
        }

        stub_request(:put, "#{base_url}/users/1.json")
          .with(body: /New/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/users/1.json")
          .to_return(status: 200, body: {
            'user' => { 'id' => 1, 'firstname' => 'New' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
      end
    end

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({ firstname: 'New' })

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

    context 'when user not found' do
      it 'returns error response' do
        params = {
          id: 999,
          firstname: 'Updated'
        }

        stub_request(:put, "#{base_url}/users/999.json")
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
          mail: ''
        }

        stub_request(:put, "#{base_url}/users/1.json")
          .with(body: /mail/)
          .to_return(status: 422, body: { 'errors' => ['Mail cannot be blank'] }.to_json,
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
          firstname: 'Updated'
        }

        stub_request(:put, "#{base_url}/users/1.json")
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
          firstname: 'Updated'
        }

        stub_request(:put, "#{base_url}/users/1.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
