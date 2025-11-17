# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/delete_issue'

RSpec.describe RedmineMcpServer::Tools::Issues::DeleteIssueTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('delete_issue')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Delete an issue')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:id)
      expect(schema[:properties]).to have_key(:confirm)
      expect(schema[:required]).to include('id', 'confirm')
    end
  end

  describe '#call' do
    context 'with valid parameters and confirmation' do
      it 'deletes the issue' do
        params = {
          id: 1,
          confirm: true
        }

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => { 'id' => 1, 'subject' => 'Test Issue', 'project' => { 'name' => 'Test Project' } }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:delete, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data][:message]).to include('permanently deleted')
        expect(result[:data][:deleted_issue_id]).to eq(1)
        expect(result[:data][:deleted_issue_subject]).to eq('Test Issue')
      end
    end

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({ confirm: true })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when confirm is missing' do
      it 'returns error response' do
        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: confirm')
      end
    end

    context 'when confirm is false' do
      it 'returns error response' do
        params = {
          id: 1,
          confirm: false
        }

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('explicit confirmation')
      end
    end

    context 'when confirm is not boolean true' do
      it 'returns error response for string "true"' do
        params = {
          id: 1,
          confirm: 'true'
        }

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('explicit confirmation')
      end
    end

    context 'when issue not found' do
      it 'returns error response' do
        params = {
          id: 999,
          confirm: true
        }

        stub_request(:get, "#{base_url}/issues/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('Error')
        expect(result[:error][:message]).to include('not found')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          id: 1,
          confirm: true
        }

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => { 'id' => 1, 'subject' => 'Test', 'project' => { 'name' => 'Test' } }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:delete, "#{base_url}/issues/1.json")
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
          confirm: true
        }

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => { 'id' => 1, 'subject' => 'Test', 'project' => { 'name' => 'Test' } }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:delete, "#{base_url}/issues/1.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
