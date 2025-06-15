# frozen_string_literal: true

module JsonRpc
  class Request
    attr_reader :jsonrpc, :method, :id, :params

    def initialize(id:, jsonrpc:, method:, params:)
      @id = id
      @jsonrpc = jsonrpc
      @method = method
      @params = params
    end

    def valid?
      return false unless jsonrpc == '2.0'
      return false if method.nil?

      true
    end
  end

  class Response
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def as_json(_options = {})
      {
        jsonrpc: '2.0',
        id:
      }
    end
  end

  class Success < Response
    attr_reader :result

    def initialize(id:, result:)
      super(id: id)

      @result = result
    end

    def as_json(_options = nil)
      {
        **super,
        result:
      }
    end
  end

  class Error < Response
    attr_reader :error_code, :message, :data

    def initialize(id:, error_code:, message:, data:)
      super(id: id)

      @error_code = error_code
      @message = message
      @data = data
    end

    def as_json(_options = {})
      {
        **super,
        error: {
          code: error_code,
          message:,
          data:
        }
      }
    end

    def self.invalid_request(data: nil)
      Error.new(
        id: nil,
        error_code: -32_600,
        message: 'Invalid Request',
        data: data
      )
    end

    def self.parse_error(id:, data: nil)
      Error.new(
        id:,
        error_code: -32_700,
        message: 'Parse error',
        data:
      )
    end

    def self.method_not_found(id:, method: nil)
      Error.new(
        id:,
        error_code: -32_601,
        message: 'Method not found',
        data: method ? "Method '#{method}' is not supported" : nil
      )
    end

    def self.invalid_params(id:, data: nil)
      Error.new(
        id:,
        error_code: -32_602,
        message: 'Invalid params',
        data:
      )
    end

    # Custom error for authorization failures
    # JSON-RPC reserved code range for server errors is −32000 to −32099
    # We pick −32001 to denote Unauthorized.
    def self.unauthorized(id: nil, data: nil)
      Error.new(
        id:,
        error_code: -32_001,
        message: data,
        data:
      )
    end
  end
end
