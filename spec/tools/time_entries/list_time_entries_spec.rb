# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/time_entries/list_time_entries'

RSpec.describe RedmineMcpServer::Tools::TimeEntries::ListTimeEntriesTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_time_entries')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List time entries')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:user_id)
      expect(schema[:properties]).to have_key(:project_id)
      expect(schema[:properties]).to have_key(:issue_id)
      expect(schema[:properties]).to have_key(:limit)
      expect(schema[:properties]).to have_key(:offset)
    end
  end

  describe '#call' do
    context 'without filters' do
      it 'lists all time entries' do
        response_body = {
          'time_entries' => [
            { 'id' => 1, 'hours' => 2.5, 'comments' => 'Work done' },
            { 'id' => 2, 'hours' => 3.0, 'comments' => 'More work' }
          ],
          'total_count' => 2,
          'limit' => 25,
          'offset' => 0
        }

        stub_request(:get, "#{base_url}/time_entries.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:time_entries].length).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
      end
    end

    context 'with user filter' do
      it 'filters by user_id' do
        response_body = {
          'time_entries' => [{ 'id' => 1, 'hours' => 2.5 }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/time_entries.json?user_id=5")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ user_id: 5 })

        expect(result[:success]).to be true
        expect(result[:data][:time_entries].length).to eq(1)
      end
    end

    context 'with project filter' do
      it 'filters by project_id' do
        response_body = {
          'time_entries' => [{ 'id' => 1, 'hours' => 2.5 }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/time_entries.json?project_id=3")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ project_id: 3 })

        expect(result[:success]).to be true
      end
    end

    context 'with date range' do
      it 'filters by from and to dates' do
        response_body = {
          'time_entries' => [{ 'id' => 1, 'hours' => 2.5 }],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/time_entries.json?from=2024-01-01&to=2024-01-31")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ from: '2024-01-01', to: '2024-01-31' })

        expect(result[:success]).to be true
      end
    end

    context 'with pagination' do
      it 'supports limit and offset' do
        response_body = {
          'time_entries' => [{ 'id' => 11 }],
          'total_count' => 50,
          'limit' => 10,
          'offset' => 10
        }

        stub_request(:get, "#{base_url}/time_entries.json?limit=10&offset=10")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ limit: 10, offset: 10 })

        expect(result[:success]).to be true
        expect(result[:data][:limit]).to eq(10)
        expect(result[:data][:offset]).to eq(10)
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/time_entries.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
