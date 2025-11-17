# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/remove_watcher'

RSpec.describe RedmineMcpServer::Tools::Issues::RemoveIssueWatcherTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('remove_issue_watcher')
    end
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'removes a watcher from the issue' do
        params = {
          issue_id: 1,
          user_id: 5
        }

        stub_request(:delete, "#{base_url}/issues/1/watchers/5.json")
          .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('removed as watcher')
      end
    end

    context 'when issue_id is missing' do
      it 'returns error response' do
        result = tool.call({ user_id: 5 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: issue_id')
      end
    end

    context 'when user_id is missing' do
      it 'returns error response' do
        result = tool.call({ issue_id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: user_id')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          issue_id: 1,
          user_id: 5
        }

        stub_request(:delete, "#{base_url}/issues/1/watchers/5.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
