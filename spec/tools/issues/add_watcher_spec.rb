# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/add_watcher'

RSpec.describe RedmineMcpServer::Tools::Issues::AddIssueWatcherTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('add_issue_watcher')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Add a watcher')
    end
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'adds a watcher to the issue' do
        params = {
          issue_id: 1,
          user_id: 5
        }

        stub_request(:post, "#{base_url}/issues/1/watchers.json")
          .with(body: /user_id/)
          .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('added as watcher')
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

        stub_request(:post, "#{base_url}/issues/1/watchers.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when issue not found' do
      it 'returns error response' do
        params = {
          issue_id: 999,
          user_id: 5
        }

        stub_request(:post, "#{base_url}/issues/999/watchers.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end
  end
end
