# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/copy_issue'

RSpec.describe RedmineMcpServer::Tools::Issues::CopyIssueTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('copy_issue')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Copy an issue')
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
    context 'with minimum parameters' do
      it 'copies the issue' do
        params = {
          id: 1,
          project_id: 2
        }

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => {
              'id' => 1,
              'subject' => 'Original Issue',
              'description' => 'Description',
              'tracker' => { 'id' => 1 },
              'priority' => { 'id' => 2 }
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, "#{base_url}/issues.json")
          .with(body: /Original Issue/)
          .to_return(status: 201, body: { 'issue' => { 'id' => 100 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['copied_from_issue_id']).to eq(1)
      end
    end

    context 'with link parameter' do
      it 'creates a relation' do
        params = {
          id: 1,
          project_id: 1,
          link: true
        }

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 200, body: {
            'issue' => {
              'id' => 1,
              'subject' => 'Test',
              'tracker' => { 'id' => 1 }
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, "#{base_url}/issues.json")
          .to_return(status: 201, body: { 'issue' => { 'id' => 100 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, "#{base_url}/issues/1/relations.json")
          .with(body: /copied_to/)
          .to_return(status: 201, body: { 'relation' => { 'id' => 1 } }.to_json,
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

    context 'when source issue not found' do
      it 'returns error response' do
        params = {
          id: 999,
          project_id: 1
        }

        stub_request(:get, "#{base_url}/issues/999.json")
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

        stub_request(:get, "#{base_url}/issues/1.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
