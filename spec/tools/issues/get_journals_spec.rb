# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/get_journals'

RSpec.describe RedmineMcpServer::Tools::Issues::GetIssueJournalsTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('get_issue_journals')
    end
  end

  describe '#call' do
    context 'with valid issue_id' do
      it 'returns journals for the issue' do
        response_body = {
          'issue' => {
            'id' => 1,
            'journals' => [
              { 'id' => 1, 'notes' => 'First comment' },
              { 'id' => 2, 'notes' => 'Second comment' }
            ]
          }
        }

        stub_request(:get, "#{base_url}/issues/1.json?include=journals")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ issue_id: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:journals]).to be_an(Array)
        expect(result[:data][:journals].size).to eq(2)
      end
    end

    context 'when issue_id is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: issue_id')
      end
    end

    context 'when issue not found' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/issues/999.json?include=journals")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ issue_id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/issues/1.json?include=journals")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ issue_id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:get, "#{base_url}/issues/1.json?include=journals")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ issue_id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
