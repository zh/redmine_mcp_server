# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/move_issue'

RSpec.describe RedmineMcpServer::Tools::Issues::MoveIssueTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('move_issue')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Move an issue')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:id)
      expect(schema[:properties]).to have_key(:project_id)
      expect(schema[:required]).to include('id', 'project_id')
    end
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'moves the issue to another project' do
        params = {
          id: 1,
          project_id: 2
        }

        stub_request(:put, "#{base_url}/issues/1.json")
          .with(body: /project_id/)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => { 'id' => 1, 'project' => { 'id' => 2 } }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(1)
      end
    end

    context 'with tracker change' do
      it 'moves and changes tracker' do
        params = {
          id: 1,
          project_id: 2,
          tracker_id: 3
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

    context 'when id is missing' do
      it 'returns error response' do
        result = tool.call({ project_id: 2 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: id')
      end
    end

    context 'when project_id is missing' do
      it 'returns error response' do
        result = tool.call({ id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: project_id')
      end
    end

    context 'when issue not found' do
      it 'returns error response' do
        params = {
          id: 999,
          project_id: 2
        }

        stub_request(:put, "#{base_url}/issues/999.json")
          .to_return(status: 404, body: { error: 'Not Found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('NotFoundError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          id: 1,
          project_id: 2
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
          project_id: 2
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
