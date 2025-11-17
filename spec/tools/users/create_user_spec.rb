# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tools/users/create_user'

RSpec.describe RedmineMcpServer::Tools::Users::CreateUserTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#name' do
    it 'returns the tool name' do
      expect(tool.name).to eq('create_user')
    end
  end

  describe '#description' do
    it 'returns a description' do
      expect(tool.description).to be_a(String)
      expect(tool.description).to include('Create a new user')
    end
  end

  describe '#input_schema' do
    it 'returns a valid schema with required fields' do
      schema = tool.input_schema
      expect(schema[:type]).to eq('object')
      expect(schema[:properties]).to have_key(:login)
      expect(schema[:properties]).to have_key(:firstname)
      expect(schema[:properties]).to have_key(:lastname)
      expect(schema[:properties]).to have_key(:mail)
      expect(schema[:required]).to include('login', 'firstname', 'lastname', 'mail')
    end
  end

  describe '#call' do
    context 'with minimum required parameters' do
      it 'creates a new user' do
        params = {
          login: 'jdoe',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'john@example.com'
        }

        response_body = {
          'user' => {
            'id' => 100,
            'login' => 'jdoe',
            'firstname' => 'John',
            'lastname' => 'Doe',
            'mail' => 'john@example.com'
          }
        }

        stub_request(:post, "#{base_url}/users.json")
          .with(body: /jdoe.*John/)
          .to_return(status: 201, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
        expect(result[:data]['login']).to eq('jdoe')
      end
    end

    context 'with all optional parameters' do
      it 'creates user with all fields' do
        params = {
          login: 'jdoe',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'john@example.com',
          password: 'SecurePass123',
          admin: true,
          mail_notification: 'all'
        }

        stub_request(:post, "#{base_url}/users.json")
          .with(body: /jdoe/)
          .to_return(status: 201, body: { 'user' => { 'id' => 100 } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be true
        expect(result[:data]['id']).to eq(100)
      end
    end

    context 'when required field is missing' do
      it 'returns error for missing login' do
        result = tool.call({ firstname: 'John', lastname: 'Doe', mail: 'john@example.com' })

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include('Missing required parameters: login')
      end
    end

    context 'when validation fails' do
      it 'returns validation error' do
        params = {
          login: 'admin',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'john@example.com'
        }

        stub_request(:post, "#{base_url}/users.json")
          .to_return(status: 422, body: { 'errors' => ['Login has already been taken'] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('ValidationError')
      end
    end

    context 'when unauthorized' do
      it 'returns authentication error' do
        params = {
          login: 'jdoe',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'john@example.com'
        }

        stub_request(:post, "#{base_url}/users.json")
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
          login: 'jdoe',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'john@example.com'
        }

        stub_request(:post, "#{base_url}/users.json")
          .to_return(status: 403, body: { error: 'Forbidden' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        result = tool.call(params)

        expect(result[:success]).to be false
        expect(result[:error][:type]).to eq('AuthorizationError')
      end
    end
  end
end
