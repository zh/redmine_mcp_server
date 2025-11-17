# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/create_issue'

RSpec.describe RedmineMcpServer::Tools::Issues::CreateIssueTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_issue')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new issue')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:project_id)
      expect(schema[:properties]).to have_key(:tracker_id)
      expect(schema[:properties]).to have_key(:subject)
      expect(schema[:required]).to include('project_id', 'tracker_id', 'subject')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a new issue' do
        params = {
          project_id: 1,
          tracker_id: 1,
          subject: 'Test Issue'
        }

        response_body = {
          'issue' => {
            'id' => 100,
            'project' => { 'id' => 1 },
            'tracker' => { 'id' => 1 },
            'subject' => 'Test Issue'
          }
        }

        stub_request(:post, "#{base_url}/issues.json")
          .with(body: /Test Issue/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['subject']).to eq('Test Issue')
      end
    end

    context 'with optional parameters' do
      it 'creates issue with all fields' do
        params = {
          project_id: 1,
          tracker_id: 1,
          subject: 'Detailed Issue',
          description: 'Full description',
          priority_id: 3,
          assigned_to_id: 5,
          done_ratio: 25
        }

        stub_request(:post, "#{base_url}/issues.json")
          .with(body: /Detailed Issue/)
          .to_return(status: 201, body: { 'issue' => { 'id' => 100 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when project_id is missing' do
      it 'returns error response' do
        result = tool.call({ tracker_id: 1, subject: 'Test' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: project_id')
      end
    end

    context 'when tracker_id is missing' do
      it 'returns error response' do
        result = tool.call({ project_id: 1, subject: 'Test' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: tracker_id')
      end
    end

    context 'when subject is missing' do
      it 'returns error response' do
        result = tool.call({ project_id: 1, tracker_id: 1 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: subject')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          project_id: 1,
          tracker_id: 1,
          subject: ''
        }

        stub_request(:post, "#{base_url}/issues.json")
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
          project_id: 1,
          tracker_id: 1,
          subject: 'Test'
        }

        stub_request(:post, "#{base_url}/issues.json")
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
          project_id: 1,
          tracker_id: 1,
          subject: 'Test'
        }

        stub_request(:post, "#{base_url}/issues.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
