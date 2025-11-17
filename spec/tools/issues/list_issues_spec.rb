# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/list_issues'

RSpec.describe RedmineMcpServer::Tools::Issues::ListIssuesTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_issues')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List issues')
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
      it 'lists all issues' do
        response_body = {
          'issues' => [
            { 'id' => 1, 'subject' => 'Issue 1' },
            { 'id' => 2, 'subject' => 'Issue 2' }
          ],
          'total_count' => 2,
          'offset' => 0,
          'limit' => 25
        }

        stub_request(:get, "#{base_url}/issues.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:issues]).to be_an(Array)
        expect(result[:data][:issues].size).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
      end
    end

    context 'with project_id filter' do
      it 'filters by project' do
        response_body = {
          'issues' => [{ 'id' => 1, 'subject' => 'Project Issue' }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/issues.json?project_id=1")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ project_id: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:issues].size).to eq(1)
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        stub_request(:get, "#{base_url}/issues.json?status_id=open")
          .to_return(status: 200, body: { 'issues' => [], 'total_count' => 0 }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ status_id: 'open' })

        expect(result[:success]).to be true
      end
    end

    context 'with assigned_to_id filter' do
      it 'filters by assignee' do
        stub_request(:get, "#{base_url}/issues.json?assigned_to_id=5")
          .to_return(status: 200, body: { 'issues' => [], 'total_count' => 0 }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ assigned_to_id: 5 })

        expect(result[:success]).to be true
      end
    end

    context 'with limit parameter' do
      it 'respects the limit' do
        stub_request(:get, "#{base_url}/issues.json?limit=10")
          .to_return(status: 200, body: { 'issues' => [], 'total_count' => 0, 'limit' => 10 }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ limit: 10 })

        expect(result[:success]).to be true
        expect(result[:data][:limit]).to eq(10)
      end
    end

    context 'when API returns error' do
      it 'returns error response' do
        stub_request(:get, "#{base_url}/issues.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
