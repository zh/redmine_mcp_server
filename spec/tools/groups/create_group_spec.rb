# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/groups/create_group'

RSpec.describe RedmineMcpServer::Tools::Groups::CreateGroupTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_group')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new group')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:user_ids)
      expect(schema[:required]).to include('name')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a new group' do
        params = {
          name: 'Developers'
        }

        response_body = {
          'group' => {
            'id' => 100,
            'name' => 'Developers'
          }
        }

        stub_request(:post, "#{base_url}/groups.json")
          .with(body: /Developers/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['name']).to eq('Developers')
      end
    end

    context 'with user_ids parameter' do
      it 'creates group with initial members' do
        params = {
          name: 'Developers',
          user_ids: [1, 2, 3]
        }

        stub_request(:post, "#{base_url}/groups.json")
          .with(body: /Developers/)
          .to_return(status: 201, body: { 'group' => { 'id' => 100 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
      end
    end

    context 'when name is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: name')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          name: ''
        }

        stub_request(:post, "#{base_url}/groups.json")
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
          name: 'Developers'
        }

        stub_request(:post, "#{base_url}/groups.json")
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
          name: 'Developers'
        }

        stub_request(:post, "#{base_url}/groups.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
