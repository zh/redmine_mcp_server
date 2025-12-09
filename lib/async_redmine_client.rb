# frozen_string_literal: true

require 'cgi'
require 'async'
require 'async/http/internet'
require 'async/http/endpoint'
require 'protocol/http/headers'
require 'json'

# Monkey-patch String#blank? if not available (ActiveSupport alternative)
unless ''.respond_to?(:blank?)
  class String
    def blank?
      empty?
    end
  end

  class NilClass
    def blank?
      true
    end
  end
end

module RedmineMcpServer
  # Async HTTP client for interacting with Redmine REST API
  class AsyncRedmineClient
    class RedmineError < StandardError
      attr_reader :status, :response_body

      def initialize(message, status: nil, response_body: nil)
        super(message)
        @status = status
        @response_body = response_body
      end
    end

    class AuthenticationError < RedmineError; end
    class AuthorizationError < RedmineError; end
    class NotFoundError < RedmineError; end
    class ValidationError < RedmineError; end
    class ServerError < RedmineError; end

    # Maximum number of pages to fetch in paginate method (prevents OOM)
    MAX_PAGES = 100

    # Authentication types supported
    AUTH_TYPE_API_KEY = :api_key
    AUTH_TYPE_BEARER = :bearer

    attr_reader :base_url, :auth_type

    # Initialize a new Redmine client
    # @param base_url [String] Redmine instance base URL
    # @param auth_token [String] API key or Bearer token (depending on auth_type)
    # @param auth_type [Symbol] :api_key (default) or :bearer for OAuth tokens
    # @param logger [Logger] Logger instance
    # @param timeout [Integer] Connection timeout in seconds
    # @param read_timeout [Integer] Read timeout in seconds
    def initialize(base_url, auth_token, auth_type: AUTH_TYPE_API_KEY, logger: nil, timeout: nil, read_timeout: nil)
      @base_url = normalize_url(base_url)
      @auth_token = auth_token
      @auth_type = auth_type
      @logger = logger || RedmineMcpServer.logger

      # Validate auth_type
      unless [AUTH_TYPE_API_KEY, AUTH_TYPE_BEARER].include?(@auth_type)
        raise ArgumentError, "Invalid auth_type: #{auth_type}. Must be :api_key or :bearer"
      end

      # Timeout configuration
      @timeout = timeout || ENV.fetch('HTTP_TIMEOUT', '30').to_i
      @read_timeout = read_timeout || ENV.fetch('HTTP_READ_TIMEOUT', '60').to_i

      # Create endpoint
      @endpoint = Async::HTTP::Endpoint.parse(@base_url, timeout: @timeout)
    end

    # GET request to Redmine API
    # @param path [String] API endpoint path (e.g., '/projects.json')
    # @param params [Hash] Query parameters
    # @return [Hash] Parsed JSON response
    def get(path, params = {})
      request(:get, path, params: params)
    end

    # POST request to Redmine API
    # @param path [String] API endpoint path
    # @param body [Hash] Request body
    # @return [Hash] Parsed JSON response
    def post(path, body = {})
      request(:post, path, body: body)
    end

    # PUT request to Redmine API
    # @param path [String] API endpoint path
    # @param body [Hash] Request body
    # @return [Hash] Parsed JSON response
    def put(path, body = {})
      request(:put, path, body: body)
    end

    # DELETE request to Redmine API
    # @param path [String] API endpoint path
    # @return [Hash] Parsed JSON response (usually empty)
    def delete(path)
      request(:delete, path)
    end

    # Paginated GET request
    # @param path [String] API endpoint path
    # @param params [Hash] Query parameters
    # @param limit [Integer] Number of items per page (max 100)
    # @yield [items, offset, total_count] Block to process each page
    # @return [Array] All items if no block given
    # @raise [RedmineError] if MAX_PAGES is exceeded
    def paginate(path, params = {}, limit: 100)
      all_items = []
      offset = params[:offset].to_i
      params = params.merge(limit: limit)
      pages_fetched = 0

      loop do
        # Safety check: prevent excessive pagination
        if pages_fetched >= MAX_PAGES
          raise RedmineError, "Maximum pagination limit reached (#{MAX_PAGES} pages). " \
                              'Use a block to process pages incrementally or filter your query.'
        end

        params[:offset] = offset
        response = get(path, params)

        # Detect the collection key (e.g., 'projects', 'issues', 'users')
        collection_key = detect_collection_key(response)
        items = response[collection_key] || []
        total_count = response['total_count'] || items.size

        if block_given?
          yield items, offset, total_count
        else
          all_items.concat(items)
        end

        pages_fetched += 1
        break if items.size < limit || offset + items.size >= total_count

        offset += limit
      end

      block_given? ? nil : all_items
    end

    # Test connection to Redmine
    # @return [Boolean] true if connection successful
    # @raise [RedmineError] if connection fails
    def test_connection
      response = get('/users/current.json')
      response.key?('user')
    rescue RedmineError => e
      @logger.error "Connection test failed: #{e.message}"
      raise
    end

    private

    def request(method, path, params: {}, body: nil)
      path = ensure_json_extension(path)
      url = build_url(path, params)

      @logger.debug "#{method.upcase} #{url}" if @logger.debug?
      @logger.debug "Body: #{body.inspect}" if body && @logger.debug?

      # Execute request in async context with optional timeout enforcement
      # (timeout disabled in test environment to allow mocks to work)
      Async do |task|
        if test_environment?
          # No timeout in test environment - allows mocks to work properly
          begin
            client = Async::HTTP::Internet.new

            headers = Protocol::HTTP::Headers[build_headers]
            request_body = body ? JSON.generate(body) : nil

            response = case method
                       when :get
                         client.get(url, headers: headers)
                       when :post
                         client.post(url, headers: headers, body: request_body)
                       when :put
                         client.put(url, headers: headers, body: request_body)
                       when :delete
                         client.delete(url, headers: headers)
                       else
                         raise ArgumentError, "Unsupported HTTP method: #{method}"
                       end

            handle_response(response)
          ensure
            client&.close
          end
        else
          # Apply timeout in non-test environments
          task.with_timeout(@read_timeout) do
            client = Async::HTTP::Internet.new

            headers = Protocol::HTTP::Headers[build_headers]
            request_body = body ? JSON.generate(body) : nil

            response = case method
                       when :get
                         client.get(url, headers: headers)
                       when :post
                         client.post(url, headers: headers, body: request_body)
                       when :put
                         client.put(url, headers: headers, body: request_body)
                       when :delete
                         client.delete(url, headers: headers)
                       else
                         raise ArgumentError, "Unsupported HTTP method: #{method}"
                       end

            handle_response(response)
          ensure
            client&.close
          end
        end
      end.wait
    rescue Async::TimeoutError
      @logger.error "Request timeout after #{@read_timeout}s: #{method.upcase} #{url}"
      raise ServerError.new("Request timeout after #{@read_timeout} seconds", status: 408, response_body: nil)
    rescue RedmineError
      raise # Re-raise RedmineError unchanged
    rescue StandardError => e
      @logger.error "Async HTTP error: #{e.class} - #{e.message}"
      raise ServerError.new("Network error: #{e.message}", status: nil, response_body: nil)
    end

    def build_headers
      headers = [
        ['accept', 'application/json'],
        ['content-type', 'application/json'],
        ['accept-encoding', 'gzip, deflate']
      ]

      # Add authentication header based on auth_type
      case @auth_type
      when AUTH_TYPE_API_KEY
        headers.unshift(['x-redmine-api-key', @auth_token])
      when AUTH_TYPE_BEARER
        headers.unshift(['authorization', "Bearer #{@auth_token}"])
      end

      headers
    end

    def build_url(path, params)
      url = "#{@base_url}#{path}"

      if params.any?
        query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
        url += "?#{query_string}"
      end

      url
    end

    def handle_response(response)
      body_text = response.read

      case response.status
      when 200, 201, 207
        body_text.blank? ? {} : JSON.parse(body_text)
      when 204
        {} # No content
      when 401
        raise AuthenticationError.new(
          'Invalid or missing API key',
          status: 401,
          response_body: parse_body(body_text)
        )
      when 403
        raise AuthorizationError.new(
          'Insufficient permissions',
          status: 403,
          response_body: parse_body(body_text)
        )
      when 404
        raise NotFoundError.new(
          'Resource not found',
          status: 404,
          response_body: parse_body(body_text)
        )
      when 422
        errors = extract_errors(parse_body(body_text))
        raise ValidationError.new(
          "Validation failed: #{errors.join(', ')}",
          status: 422,
          response_body: parse_body(body_text)
        )
      when 500..599
        raise ServerError.new(
          "Server error (#{response.status})",
          status: response.status,
          response_body: parse_body(body_text)
        )
      else
        raise RedmineError.new(
          "Unexpected response (#{response.status})",
          status: response.status,
          response_body: parse_body(body_text)
        )
      end
    end

    def parse_body(body_text)
      return {} if body_text.blank?

      JSON.parse(body_text)
    rescue JSON::ParserError
      {}
    end

    def extract_errors(body)
      return [] unless body.is_a?(Hash)

      if body['errors']
        body['errors'].is_a?(Array) ? body['errors'] : [body['errors']]
      elsif body['error']
        [body['error']]
      else
        ['Unknown error']
      end
    end

    def detect_collection_key(response)
      # Common collection keys in Redmine API
      %w[projects issues users time_entries versions wiki_pages
         issue_statuses trackers custom_fields roles groups
         memberships issue_relations news queries attachments].find do |key|
        response.key?(key)
      end
    end

    def normalize_url(url)
      url = url.to_s.strip
      url = url.chomp('/')
      url = "http://#{url}" unless url =~ %r{\Ahttps?://}

      # Validate URL protocol for security
      validate_url_protocol!(url)

      url
    end

    # Validate that URL only uses HTTP/HTTPS protocols
    # @param url [String] URL to validate
    # @raise [ArgumentError] if URL uses invalid protocol
    def validate_url_protocol!(url)
      require 'uri'

      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError => e
        raise ArgumentError, "Invalid URL format: #{e.message}"
      end

      # Only allow HTTP and HTTPS protocols
      return if uri.scheme&.match?(/\A(http|https)\z/)

      raise ArgumentError, "Invalid URL protocol '#{uri.scheme}'. Only HTTP and HTTPS are allowed."
    end

    # Check if we're running in test environment
    # @return [Boolean] true if in test environment
    def test_environment?
      ENV['RACK_ENV'] == 'test' || ENV['RAILS_ENV'] == 'test'
    end

    def ensure_json_extension(path)
      return path if path.end_with?('.json')
      return path if path.include?('.json?')

      path.include?('?') ? path.sub('?', '.json?') : "#{path}.json"
    end
  end
end
