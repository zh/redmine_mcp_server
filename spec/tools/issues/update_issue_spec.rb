# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/update_issue'

RSpec.describe RedmineMcpServer::Tools::Issues::UpdateIssueTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('update_issue')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Update an existing issue')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required id' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:id)
      expect(schema[:required]).to include('id')
    end
  end

  describe '#call' do
    context 'with single field update' do
      it 'updates issue subject' do
        params = {
          id: 1,
          subject: 'Updated Subject'
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .with(body: /Updated Subject/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => { 'id' => 1, 'subject' => 'Updated Subject' }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['subject']).to eq('Updated Subject')
      end
    end

    context 'with multiple field updates' do
      it 'updates multiple fields' do
        params = {
          id: 1,
          subject: 'New Subject',
          status_id: 2,
          assigned_to_id: 5
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: { 'issue' => { 'id' => 1 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'with notes parameter' do
      it 'adds a comment to the issue' do
        params = {
          id: 1,
          notes: 'Adding a comment'
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .with(body: /Adding a comment/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: { 'issue' => { 'id' => 1 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({ subject: 'New' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when no fields provided for update' do
      it 'returns error response' do
        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('At least one field must be provided')
      end
    end

    context 'when issue not found' do
      it 'returns error response' do
        params = {
          id: 999,
          subject: 'Updated'
        }

        stub_request(:put, "#{base_url}/issues/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          id: 1,
          subject: ''
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .to_return(status: 422, body: { 'errors' => ['Subject cannot be blank'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          id: 1,
          subject: 'Updated'
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end

    context 'when forbidden' do
      it 'returns authorization error' do
        params = {
          id: 1,
          subject: 'Updated'
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
