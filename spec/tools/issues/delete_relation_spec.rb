# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/delete_relation'

RSpec.describe RedmineMcpServer::Tools::Issues::DeleteIssueRelationTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('delete_issue_relation')
    end
  end

  describe '#call' do
    context 'with valid relation_id' do
      it 'deletes the relation' do
        params = {
          relation_id: 10
        }

        stub_request(:delete, "#{base_url}/relations/10.json")
          .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('deleted')
        expect(result[:data][:deleted_relation_id]).to eq(10)
      end
    end

    context 'when relation_id is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: relation_id')
      end
    end

    context 'when relation not found' do
      it 'returns error response' do
        stub_request(:delete, "#{base_url}/relations/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ relation_id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:delete, "#{base_url}/relations/10.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ relation_id: 10 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:delete, "#{base_url}/relations/10.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ relation_id: 10 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
