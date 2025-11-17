# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/users/list_users'

RSpec.describe RedmineMcpServer::Tools::Users::ListUsersTool do
  let(:redmine_client) { RedmineMcpServer.redmine_client }
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_users')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List all users')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:limit)
      expect(schema[:properties]).to have_key(:offset)
      expect(schema[:properties]).to have_key(:status)
      expect(schema[:properties]).to have_key(:name)
      expect(schema[:properties]).to have_key(:group_id)
    end
  end

  describe '#call' do
    context 'with default parameters' do
      it 'lists all users' do
        response_body = {
          'users' => [
            { 'id' => 1, 'login' => 'admin', 'firstname' => 'Admin', 'lastname' => 'User' },
            { 'id' => 2, 'login' => 'john', 'firstname' => 'John', 'lastname' => 'Doe' }
          ],
          'total_count' => 2,
          'offset' => 0,
          'limit' => 25
        }

        stub_request(:get, "#{base_url}/users.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:users]).to be_an(Array)
        expect(result[:data][:users].size).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
      end
    end

    context 'with limit parameter' do
      it 'respects the limit parameter' do
        response_body = {
          'users' => [{ 'id' => 1, 'login' => 'admin' }],
          'total_count' => 10,
          'limit' => 1,
          'offset' => 0
        }

        stub_request(:get, "#{base_url}/users.json?limit=1")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ limit: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:limit]).to eq(1)
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        response_body = {
          'users' => [{ 'id' => 1, 'login' => 'admin', 'status' => 1 }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/users.json?status=1")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ status: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:users]).to be_an(Array)
      end
    end

    context 'with name filter' do
      it 'filters by name' do
        response_body = {
          'users' => [{ 'id' => 2, 'login' => 'john', 'firstname' => 'John' }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/users.json?name=john")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ name: 'john' })

        expect(result[:success]).to be true
        expect(result[:data][:users]).to be_an(Array)
      end
    end

    context 'with group_id filter' do
      it 'filters by group membership' do
        response_body = {
          'users' => [{ 'id' => 2, 'login' => 'john' }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/users.json?group_id=5")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ group_id: 5 })

        expect(result[:success]).to be true
        expect(result[:data][:users]).to be_an(Array)
      end
    end

    context 'when API returns error' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/users.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
