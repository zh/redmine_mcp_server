# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/time_entries/get_time_entry'

RSpec.describe RedmineMcpServer::Tools::TimeEntries::GetTimeEntryTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('get_time_entry')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Get detailed information')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:time_entry_id)
      expect(schema[:required]).to include('time_entry_id')
    end
  end

  describe '#call' do
    context 'with valid time_entry_id' do
      it 'retrieves the time entry' do
        response_body = {
          'time_entry' => {
            'id' => 123,
            'hours' => 2.5,
            'comments' => 'Development work',
            'spent_on' => '2024-01-15',
            'activity' => { 'id' => 9, 'name' => 'Development' },
            'project' => { 'id' => 1, 'name' => 'My Project' },
            'user' => { 'id' => 5, 'name' => 'John Doe' }
          }
        }

        stub_request(:get, "#{base_url}/time_entries/123.json")
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ time_entry_id: 123 })

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(123)
        expect(result[:data]['hours']).to eq(2.5)
        expect(result[:data]['comments']).to eq('Development work')
      end
    end

    context 'when time_entry_id is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: time_entry_id')
      end
    end

    context 'when time entry not found' do
      it 'returns not found error' do
        stub_request(:get, "#{base_url}/time_entries/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ time_entry_id: 999 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/time_entries/123.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ time_entry_id: 123 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
