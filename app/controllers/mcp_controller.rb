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
    requests.length > 1
  end

  def requests
    return handle_json_request if json_request?

    handle_params_request
  rescue JSON::ParserError
    []
  end

  def json_request?
    request.content_type&.include?('application/json')
  end

  def handle_json_request
    body = request.body.read
    request.body.rewind
    return [] if body.blank?

    parsed = JSON.parse(body)
    parsed.is_a?(Array) ? parsed : [parsed]
  end

  def handle_params_request
    params['_json'] || [params['mcp']]
  end

  def process_requests # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    requests.filter_map do |request| # rubocop:disable Metrics/BlockLength
      next JsonRpc::Error.invalid_request unless request.is_a? Hash

      id, jsonrpc, method, params = request.values_at('id', 'jsonrpc', 'method', 'params')

      rpc_request = JsonRpc::Request.new(
        id:, jsonrpc:, method:, params:
      )

      next JsonRpc::Error.invalid_request unless rpc_request.valid?

      next nil if rpc_request.id.nil?

      case rpc_request.method.downcase
      when 'initialize'
        handle_initialize(rpc_request)
      when 'tools/list'
        handle_tools_list(rpc_request)
      when 'tools/call'
        handle_tools_call(rpc_request)
      when 'resources/list'
        handle_resources_list(rpc_request)
      when 'resources/read'
        handle_resources_read(rpc_request)
      when 'prompts/list'
        handle_prompts_list(rpc_request)
      when 'prompts/get'
        handle_prompts_get(rpc_request)
      when 'ping'
        handle_prompts_ping(rpc_request)
      else
        JsonRpc::Error.method_not_found(id: rpc_request.id, method: rpc_request.method)
      end
    end
  end

  def validate_content_type
    return if request.content_type&.include? 'application/json'

    render pretty_json: JsonRpc::Error.invalid_request(data: "Request must have content type: 'application/json'")
  end

  # MCP Protocol Handlers

  def handle_initialize(rpc_request)
    JsonRpc::Success.new(
      id: rpc_request.id,
      result: {
        protocolVersion: '2024-11-05',
        capabilities: {
          tools: {},
          resources: {},
          prompts: {}
        },
        serverInfo: {
          name: 'Edgar MCP Server',
          version: '1.0.0'
        }
      }
    )
  end

  def handle_tools_list(rpc_request)
    JsonRpc::Success.new(
      id: rpc_request.id,
      result: {
        tools: [
          # Example tool - replace with your actual tools
          {
            name: 'echo',
            description: 'Echo back the input text',
            inputSchema: {
              type: 'object',
              properties: {
                text: {
                  type: 'string',
                  description: 'Text to echo back'
                }
              },
              required: ['text']
            }
          }
        ]
      }
    )
  end

  def handle_tools_call(rpc_request)
    tool_name = rpc_request.params&.dig('name')
    arguments = rpc_request.params&.dig('arguments') || {}

    case tool_name
    when 'echo'
      JsonRpc::Success.new(
        id: rpc_request.id,
        result: {
          content: [
            {
              type: 'text',
              text: "Echo: #{arguments['text']}"
            }
          ]
        }
      )
    else
      JsonRpc::Error.invalid_params(id: rpc_request.id, data: "Unknown tool: #{tool_name}")
    end
  end

  def handle_resources_list(rpc_request)
    JsonRpc::Success.new(
      id: rpc_request.id,
      result: {
        resources: [
          # Example resource - replace with your actual resources
          {
            uri: 'file:///example.txt',
            name: 'Example File',
            description: 'An example file resource',
            mimeType: 'text/plain'
          }
        ]
      }
    )
  end

  def handle_resources_read(rpc_request)
    uri = rpc_request.params&.dig('uri')

    # Example implementation - replace with actual resource reading logic
    case uri
    when 'file:///example.txt'
      JsonRpc::Success.new(
        id: rpc_request.id,
        result: {
          contents: [
            {
              uri: uri,
              mimeType: 'text/plain',
              text: 'This is example content from the file resource.'
            }
          ]
        }
      )
    else
      JsonRpc::Error.invalid_params(id: rpc_request.id, data: "Unknown resource URI: #{uri}")
    end
  end

  def handle_prompts_list(rpc_request)
    JsonRpc::Success.new(
      id: rpc_request.id,
      result: {
        prompts: [
          # Example prompt - replace with your actual prompts
          {
            name: 'summarize',
            description: 'Summarize the given text',
            arguments: [
              {
                name: 'text',
                description: 'Text to summarize',
                required: true
              }
            ]
          }
        ]
      }
    )
  end

  def handle_prompts_get(rpc_request)
    prompt_name = rpc_request.params&.dig('name')
    arguments = rpc_request.params&.dig('arguments') || {}

    case prompt_name
    when 'summarize'
      text = arguments['text']
      JsonRpc::Success.new(
        id: rpc_request.id,
        result: {
          description: 'Summarize the following text',
          messages: [
            {
              role: 'user',
              content: {
                type: 'text',
                text: "Please summarize the following text:\n\n#{text}"
              }
            }
          ]
        }
      )
    else
      JsonRpc::Error.invalid_params(id: rpc_request.id, data: "Unknown prompt: #{prompt_name}")
    end
  end

  def handle_prompts_ping(rpc_request)
    JsonRpc::Success.new(
      id: rpc_request.id,
      result: {}
    )
  end
end
