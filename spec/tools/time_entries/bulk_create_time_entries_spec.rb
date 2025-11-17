# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/time_entries/bulk_create_time_entries'

RSpec.describe RedmineMcpServer::Tools::TimeEntries::BulkCreateTimeEntriesTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('bulk_create_time_entries')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create multiple time entries')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:time_entries)
      expect(schema[:required]).to include('time_entries')
    end
  end

  describe '#call' do
    context 'with valid time entries array' do
      it 'creates multiple time entries' do
        params = {
          time_entries: [
            { issue_id: 10, hours: 2.5, activity_id: 9, comments: 'Work 1' },
            { issue_id: 11, hours: 3.0, activity_id: 9, comments: 'Work 2' },
            { project_id: 5, hours: 1.5, activity_id: 10, comments: 'Work 3' }
          ]
        }

        response_body = {
          'created' => [
            { 'id' => 100, 'hours' => 2.5 },
            { 'id' => 101, 'hours' => 3.0 },
            { 'id' => 102, 'hours' => 1.5 }
          ],
          'failed' => [],
          'summary' => {
            'total' => 3,
            'created' => 3,
            'failed' => 0
          }
        }

        stub_request(:post, "#{base_url}/extended_api/time_entries/bulk_create.json")
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['created'].length).to eq(3)
        expect(result[:data]['failed'].length).to eq(0)
        expect(result[:data]['summary']['created']).to eq(3)
      end
    end

    context 'with partial failures' do
      it 'returns both created and failed entries' do
        params = {
          time_entries: [
            { issue_id: 10, hours: 2.5, activity_id: 9 },
            { issue_id: 999, hours: 3.0, activity_id: 9 }
          ]
        }

        response_body = {
          'created' => [
            { 'id' => 100, 'hours' => 2.5 }
          ],
          'failed' => [
            { 'index' => 1, 'errors' => ['Issue not found'] }
          ],
          'summary' => {
            'total' => 2,
            'created' => 1,
            'failed' => 1
          }
        }

        stub_request(:post, "#{base_url}/extended_api/time_entries/bulk_create.json")
          .to_return(status: 207, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['created'].length).to eq(1)
        expect(result[:data]['failed'].length).to eq(1)
        expect(result[:data]['summary']['created']).to eq(1)
        expect(result[:data]['summary']['failed']).to eq(1)
      end
    end

    context 'when time_entries is missing' do
      it 'returns error response' do
        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: time_entries')
      end
    end

    context 'when time_entries is not an array' do
      it 'returns error response' do
        result = tool.call({ time_entries: 'not an array' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('time_entries must be an array')
      end
    end

    context 'when time_entries array is empty' do
      it 'returns error response' do
        result = tool.call({ time_entries: [] })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('time_entries array cannot be empty')
      end
    end

    context 'when all entries fail validation' do
      it 'returns validation error' do
        params = {
          time_entries: [
            { issue_id: 10, hours: -1, activity_id: 9 }
          ]
        }

        response_body = {
          'created' => [],
          'failed' => [
            { 'index' => 0, 'errors' => ['Hours must be greater than 0'] }
          ],
          'summary' => {
            'total' => 1,
            'created' => 0,
            'failed' => 1
          }
        }

        stub_request(:post, "#{base_url}/extended_api/time_entries/bulk_create.json")
          .to_return(status: 422, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          time_entries: [
            { issue_id: 10, hours: 2.5, activity_id: 9 }
          ]
        }

        stub_request(:post, "#{base_url}/extended_api/time_entries/bulk_create.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
