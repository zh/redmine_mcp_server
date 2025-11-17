# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/issues/create_relation'

RSpec.describe RedmineMcpServer::Tools::Issues::CreateIssueRelationTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_issue_relation')
    end
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'creates a relation between issues' do
        params = {
          issue_id: 1,
          issue_to_id: 2,
          relation_type: 'relates'
        }

        stub_request(:post, "#{base_url}/issues/1/relations.json")
          .with(body: /relates/)
          .to_return(status: 201, body: { 'relation' => { 'id' => 10, 'relation_type' => 'relates' } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(10)
      end
    end

    context 'with delay parameter' do
      it 'creates relation with delay' do
        params = {
          issue_id: 1,
          issue_to_id: 2,
          relation_type: 'precedes',
          delay: 5
        }

        stub_request(:post, "#{base_url}/issues/1/relations.json")
          .with(body: /delay/)
          .to_return(status: 201, body: { 'relation' => { 'id' => 10 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
      end
    end

    context 'when issue_id is missing' do
      it 'returns error response' do
        result = tool.call({ issue_to_id: 2, relation_type: 'relates' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: issue_id')
      end
    end

    context 'when issue_to_id is missing' do
      it 'returns error response' do
        result = tool.call({ issue_id: 1, relation_type: 'relates' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: issue_to_id')
      end
    end

    context 'when relation_type is missing' do
      it 'returns error response' do
        result = tool.call({ issue_id: 1, issue_to_id: 2 })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: relation_type')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          issue_id: 1,
          issue_to_id: 1,
          relation_type: 'relates'
        }

        stub_request(:post, "#{base_url}/issues/1/relations.json")
          .to_return(status: 422, body: { 'errors' => ['Cannot relate to itself'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          issue_id: 1,
          issue_to_id: 2,
          relation_type: 'relates'
        }

        stub_request(:post, "#{base_url}/issues/1/relations.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
