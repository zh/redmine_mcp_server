# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/time_entries/create_time_entry'

RSpec.describe RedmineMcpServer::Tools::TimeEntries::CreateTimeEntryTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_time_entry')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Log time')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:issue_id)
      expect(schema[:properties]).to have_key(:project_id)
      expect(schema[:properties]).to have_key(:hours)
      expect(schema[:properties]).to have_key(:activity_id)
      expect(schema[:required]).to include('hours', 'activity_id')
    end
  end

  describe '#call' do
    context 'with issue_id' do
      it 'creates time entry for issue' do
        params = {
          issue_id: 10,
          hours: 2.5,
          activity_id: 9,
          comments: 'Fixed bug'
        }

        response_body = {
          'time_entry' => {
            'id' => 100,
            'issue' => { 'id' => 10 },
            'hours' => 2.5,
            'activity' => { 'id' => 9 },
            'comments' => 'Fixed bug'
          }
        }

        stub_request(:post, "#{base_url}/time_entries.json")
          .with(body: /Fixed bug/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['hours']).to eq(2.5)
      end
    end

    context 'with project_id' do
      it 'creates time entry for project' do
        params = {
          project_id: 5,
          hours: 3.0,
          activity_id: 9,
          comments: 'General work'
        }

        response_body = {
          'time_entry' => {
            'id' => 101,
            'project' => { 'id' => 5 },
            'hours' => 3.0,
            'activity' => { 'id' => 9 }
          }
        }

        stub_request(:post, "#{base_url}/time_entries.json")
          .with(body: /General work/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(101)
      end
    end

    context 'with spent_on date' do
      it 'creates time entry with specific date' do
        params = {
          issue_id: 10,
          hours: 2.5,
          activity_id: 9,
          spent_on: '2024-01-15'
        }

        response_body = {
          'time_entry' => {
            'id' => 102,
            'spent_on' => '2024-01-15',
            'hours' => 2.5
          }
        }

        stub_request(:post, "#{base_url}/time_entries.json")
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when hours is missing' do
      it 'returns error response' do
        result = tool.call({ issue_id: 10, activity_id: 9 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: hours')
      end
    end

    context 'when activity_id is missing' do
      it 'returns error response' do
        result = tool.call({ issue_id: 10, hours: 2.5 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: activity_id')
      end
    end

    context 'when both issue_id and project_id are missing' do
      it 'returns error response' do
        result = tool.call({ hours: 2.5, activity_id: 9 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Either issue_id or project_id must be provided')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          issue_id: 10,
          hours: -1,
          activity_id: 9
        }

        stub_request(:post, "#{base_url}/time_entries.json")
          .to_return(status: 422, body: { 'errors' => ['Hours must be greater than 0'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          issue_id: 10,
          hours: 2.5,
          activity_id: 9
        }

        stub_request(:post, "#{base_url}/time_entries.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
