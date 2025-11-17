# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/time_entries/update_time_entry'

RSpec.describe RedmineMcpServer::Tools::TimeEntries::UpdateTimeEntryTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_time_entry')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing time entry')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:time_entry_id)
      expect(schema[:properties]).to have_key(:hours)
      expect(schema[:properties]).to have_key(:comments)
      expect(schema[:required]).to include('time_entry_id')
    end
  end

  describe '#call' do
    context 'with hours update' do
      it 'updates the hours' do
        params = {
          time_entry_id: 123,
          hours: 4.0
        }

        stub_request(:put, "#{base_url}/time_entries/123.json")
          .with(body: /4\.0/)
          .to_return(status: 204, headers: {})

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('updated successfully')
      end
    end

    context 'with comments update' do
      it 'updates the comments' do
        params = {
          time_entry_id: 123,
          comments: 'Updated description'
        }

        stub_request(:put, "#{base_url}/time_entries/123.json")
          .with(body: /Updated description/)
          .to_return(status: 204, headers: {})

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'with multiple fields' do
      it 'updates multiple fields' do
        params = {
          time_entry_id: 123,
          hours: 3.5,
          comments: 'Modified work',
          activity_id: 10,
          spent_on: '2024-01-20'
        }

        stub_request(:put, "#{base_url}/time_entries/123.json")
          .to_return(status: 204, headers: {})

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when time_entry_id is missing' do
      it 'returns error response' do
        result = tool.call({ hours: 3.0 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: time_entry_id')
      end
    end

    context 'when time entry not found' do
      it 'returns not found error' do
        stub_request(:put, "#{base_url}/time_entries/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ time_entry_id: 999, hours: 3.0 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          time_entry_id: 123,
          hours: -1
        }

        stub_request(:put, "#{base_url}/time_entries/123.json")
          .to_return(status: 422, body: { 'errors' => ['Hours must be greater than 0'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        stub_request(:put, "#{base_url}/time_entries/123.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ time_entry_id: 123, hours: 3.0 })

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
