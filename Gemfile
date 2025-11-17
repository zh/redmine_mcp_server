# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.1.0'

# MCP (Model Context Protocol) implementation
gem 'mcp_on_ruby', '~> 0.1.0'

# Async HTTP stack
gem 'async', '~> 2.6'
gem 'async-http', '~> 0.60'
gem 'async-io', '~> 1.40'

# JSON parsing
gem 'oj', '~> 3.16'

# Environment variable management
gem 'dotenv', '~> 2.8'

# Async web server
gem 'falcon', '~> 0.43'
gem 'protocol-http', '~> 0.25'
gem 'protocol-rack', '~> 0.4'
gem 'rack', '~> 2.2'

# Metrics (keep atomic counters for thread-safe metrics)
gem 'concurrent-ruby', '~> 1.2'

group :development, :test do
  # Testing framework
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.12'
  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.19'

  # Code quality
  gem 'rubocop', '~> 1.57', require: false
  gem 'rubocop-rspec', '~> 2.25', require: false

  # Debugging
  gem 'pry', '~> 0.14'
  gem 'pry-byebug', '~> 3.10'
end

group :development do
  # Auto-reloading
  gem 'rerun', '~> 0.14'
end
