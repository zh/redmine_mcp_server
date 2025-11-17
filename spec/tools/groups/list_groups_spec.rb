# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/groups/list_groups'

RSpec.describe RedmineMcpServer::Tools::Groups::ListGroupsTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_groups')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List all groups')
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
    context 'with default parameters' do
      it 'lists all groups' do
        response_body = {
          'groups' => [
            { 'id' => 1, 'name' => 'Developers' },
            { 'id' => 2, 'name' => 'Managers' }
          ]
        }

        stub_request(:get, "#{base_url}/groups.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:groups]).to be_an(Array)
        expect(result[:data][:groups].size).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
      end
    end

    context 'when API returns error' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/groups.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:get, "#{base_url}/groups.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
