# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'webmock/rspec'
require 'dotenv/load'

# Load the application
require_relative '../lib/redmine_mcp_server'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Configure WebMock - block ALL external connections, force use of stubs
  WebMock.disable_net_connect!

  # Reset WebMock before each test
  config.before do
    WebMock.reset!
  end

  # Helper method for stubbing Redmine API requests with proper headers
  config.include(Module.new {
    def stub_redmine_request(method, path, status: 200, body: nil, headers: {})
      base_url = RedmineMcpServer.config[:redmine_url]
      response_headers = { 'Content-Type' => 'application/json' }.merge(headers)
      response_body = body.is_a?(Hash) ? body.to_json : body

      stub_request(method, "#{base_url}#{path}")
        .to_return(status: status, body: response_body, headers: response_headers)
    end
  })
end
