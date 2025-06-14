# frozen_string_literal: true

class McpController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :validate_content_type

  def create
    responses = process_requests
    responses = responses.first unless batch_request?
    render pretty_json: responses
  end

  private

  def batch_request?
    params['_json'].is_a? Array
  end

  def requests
    params['_json'] || [params['mcp']]
  end

  def process_requests
    requests.filter_map do |request|
      next JsonRpc::Error.invalid_request unless request.is_a? Hash

      id, jsonrpc, method, params = req.values_at(:id, :jsonrpc, :method, :params)

      rpc_request = JsonRpc::Request.new(
        id:, jsonrpc:, method:, params:
      )

      next JsonRpc::Error.invalid_request unless rpc_request.valid?

      next nil if request.id.nil?

      case rpc_request.method.downcase
      when 'tools/list'
        JsonRpc::Success.new(id: request.id, result: [])
      end
    end
  end

  def validate_content_type
    return if request.content_type&.include? 'application/json'

    render pretty_json: JsonRpc::Error.invalid_request(data: "Request must have content type: 'application/json'")
  end
end
