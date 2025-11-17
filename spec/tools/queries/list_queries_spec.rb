# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/queries/list_queries'

RSpec.describe RedmineMcpServer::Tools::Queries::ListQueriesTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('list_queries')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('List all accessible queries')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with pagination' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:project_id)
      expect(schema[:properties]).to have_key(:limit)
      expect(schema[:properties]).to have_key(:offset)
    end
  end

  describe '#call' do
    context 'listing all queries' do
      it 'retrieves all queries with pagination' do
        response_body = {
          'queries' => [
            {
              'id' => 1,
              'name' => 'Open Issues',
              'is_public' => true,
              'project_id' => nil
            },
            {
              'id' => 2,
              'name' => 'My Issues',
              'is_public' => false,
              'project_id' => 1
            }
          ],
          'total_count' => 2,
          'limit' => 25,
          'offset' => 0
        }

        stub_request(:get, "#{base_url}/queries.json")
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be true
        expect(result[:data][:queries].length).to eq(2)
        expect(result[:data][:total_count]).to eq(2)
        expect(result[:data][:queries][0]['name']).to eq('Open Issues')
      end
    end

    context 'with project filter' do
      it 'filters queries by project' do
        response_body = {
          'queries' => [
            {
              'id' => 2,
              'name' => 'My Issues',
              'is_public' => false,
              'project_id' => 1
            }
          ],
          'total_count' => 1
        }

        stub_request(:get, "#{base_url}/queries.json?project_id=1")
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ project_id: 1 })

        expect(result[:success]).to be true
        expect(result[:data][:queries].length).to eq(1)
        expect(result[:data][:queries][0]['project_id']).to eq(1)
      end
    end

    context 'with pagination' do
      it 'supports limit and offset' do
        response_body = {
          'queries' => [],
          'total_count' => 50,
          'limit' => 10,
          'offset' => 20
        }

        stub_request(:get, "#{base_url}/queries.json?limit=10&offset=20")
          .to_return(status: 200, body: response_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({ limit: 10, offset: 20 })

        expect(result[:success]).to be true
        expect(result[:data][:limit]).to eq(10)
        expect(result[:data][:offset]).to eq(20)
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        stub_request(:get, "#{base_url}/queries.json")
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call({})

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthenticationError')
      end
    end
  end
end
