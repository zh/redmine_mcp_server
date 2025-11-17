# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/users/get_user'

RSpec.describe RedmineMcpServer::Tools::Users::GetUserTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('get_user')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Get detailed information')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required id' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:id)
      expect(schema[:properties]).to have_key(:include)
      expect(schema[:required]).to include('id')
    end
  end

  describe '#call' do
    context 'with valid user id' do
      it 'returns user details' do
        stub_request(:get, "#{base_url}/users/1.json")
          .to_return(status: 200, body: { 'user' => { 'id' => 1, 'login' => 'admin' } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1 })

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
      end
    end

    context 'with current as id' do
      it 'returns current user' do
        stub_request(:get, "#{base_url}/users/current.json")
          .to_return(status: 200, body: { 'user' => { 'id' => 1, 'login' => 'admin' } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 'current' })

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
      end
    end

    context 'with include parameter' do
      it 'includes related data' do
        stub_request(:get, "#{base_url}/users/1.json?include=memberships%2Cgroups")
          .to_return(status: 200, body: { 'user' => { 'id' => 1, 'memberships' => [] } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1, include: 'memberships,groups' })

        expect(result[:success]).to be true
      end
    end

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when user not found' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/users/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/users/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
