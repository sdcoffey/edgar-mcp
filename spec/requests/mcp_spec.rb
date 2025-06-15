# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MCP', type: :request do
  describe 'POST /mcp' do
    subject(:make_request) do
      post '/mcp', params: params.to_json, headers:
    end

    let(:params) { {} }
    let(:headers) { {} }
    let(:error_message) { nil }
    let(:api_key) { create(:api_key) }
    let(:token) { api_key.plain_token }

    shared_examples 'returns content-type json' do
      it 'has content-type json' do
        make_request
        expect(response.content_type).to include 'application/json'
      end
    end

    shared_examples 'returns http 200' do
      it 'returns 200' do
        make_request
        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples 'invalid request error' do
      it 'returns invalid request error' do
        make_request

        expect(response.parsed_body.deep_symbolize_keys)
          .to match(
            jsonrpc: '2.0',
            id: nil,
            error: {
              code: -32600,
              message: 'Invalid Request',
              data: error_message
            }
          )
      end
    end

    shared_examples 'authentication error' do
      it 'returns authentication error' do
        make_request

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.deep_symbolize_keys)
          .to match(
            jsonrpc: '2.0',
            id: nil,
            error: {
              code: -32001,
              message: 'Authentication Required',
              data: error_message
            }
          )
      end
    end

    describe 'authentication' do
      context 'when no API key is provided' do
        let(:headers) { { 'content-type': 'application/json' } }
        let(:params) { { jsonrpc: '2.0', method: 'initialize', id: 1 } }
        let(:error_message) { 'Missing API key' }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'authentication error'
      end

      context 'when invalid API key is provided' do
        let(:headers) { { 'content-type': 'application/json', Authorization: 'Bearer invalid-token' } }
        let(:params) { { jsonrpc: '2.0', method: 'initialize', id: 1 } }
        let(:error_message) { 'Invalid API key' }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'authentication error'
      end

      context 'when expired API key is provided' do
        let(:expired_api_key) { create(:api_key, :expired) }
        let(:headers) do
          { 'content-type': 'application/json', Authorization: "Bearer #{expired_api_key.plain_token}" }
        end
        let(:params) { { jsonrpc: '2.0', method: 'initialize', id: 1 } }
        let(:error_message) { 'API key has expired' }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'authentication error'
      end

      context 'with valid API key in Authorization header' do
        let(:headers) { { 'content-type': 'application/json', Authorization: "Bearer #{token}" } }
        let(:params) { { jsonrpc: '2.0', method: 'initialize', id: 1 } }

        it 'allows access and updates last_used_at' do
          expect { make_request }.to change { api_key.reload.last_used_at }.from(nil)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'jsonrpc validations' do
      let(:headers) { { 'content-type': 'application/json', Authorization: "Bearer #{token}" } }

      context 'when content-type headers not set' do
        let(:headers) { { Authorization: "Bearer #{token}" } }
        let(:error_message) { "Request must have content type: 'application/json'" }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'invalid request error'
      end

      context 'with incorrect version' do
        let(:params) { { jsonrpc: '1.2' } }
        let(:error_message) { nil }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'invalid request error'
      end
    end

    describe 'MCP protocol methods' do
      let(:headers) { { 'content-type': 'application/json', Authorization: "Bearer #{token}" } }

      shared_examples 'successful response' do |expected_result|
        it 'returns successful response' do
          make_request

          expect(response.parsed_body.deep_symbolize_keys)
            .to match(
              jsonrpc: '2.0',
              id: 1,
              result: expected_result
            )
        end
      end

      shared_examples 'error response' do |error_code, error_message, error_data = nil|
        it 'returns error response' do
          make_request

          expected_error = {
            code: error_code,
            message: error_message
          }
          expected_error[:data] = error_data if error_data

          expect(response.parsed_body.deep_symbolize_keys)
            .to match(
              jsonrpc: '2.0',
              id: 1,
              error: expected_error
            )
        end
      end

      describe 'initialize' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'initialize',
            id: 1,
            params: {
              protocolVersion: '2024-11-05',
              capabilities: {},
              clientInfo: { name: 'test-client', version: '1.0.0' }
            }
          }
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'successful response', {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {},
            resources: {},
            prompts: {}
          },
          serverInfo: {
            name: 'Edgar MCP Server',
            version: '1.0.0'
          },
          authentication: {
            user: String,
            organization: String,
            api_key: String
          }
        }
      end

      describe 'tools/list' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'tools/list',
            id: 1
          }
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'successful response', {
          tools: [
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
      end

      describe 'tools/call' do
        context 'with valid echo tool' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'tools/call',
              id: 1,
              params: {
                name: 'echo',
                arguments: { text: 'Hello, World!' }
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'successful response', {
            content: [
              {
                type: 'text',
                text: 'Echo: Hello, World!'
              }
            ]
          }
        end

        context 'with unknown tool' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'tools/call',
              id: 1,
              params: {
                name: 'unknown_tool',
                arguments: {}
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'error response', -32602, 'Invalid params', 'Unknown tool: unknown_tool'
        end
      end

      describe 'resources/list' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'resources/list',
            id: 1
          }
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'successful response', {
          resources: [
            {
              uri: 'file:///example.txt',
              name: 'Example File',
              description: 'An example file resource',
              mimeType: 'text/plain'
            }
          ]
        }
      end

      describe 'resources/read' do
        context 'with valid resource URI' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'resources/read',
              id: 1,
              params: {
                uri: 'file:///example.txt'
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'successful response', {
            contents: [
              {
                uri: 'file:///example.txt',
                mimeType: 'text/plain',
                text: 'This is example content from the file resource.'
              }
            ]
          }
        end

        context 'with unknown resource URI' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'resources/read',
              id: 1,
              params: {
                uri: 'file:///unknown.txt'
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'error response', -32602, 'Invalid params', 'Unknown resource URI: file:///unknown.txt'
        end
      end

      describe 'prompts/list' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'prompts/list',
            id: 1
          }
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'successful response', {
          prompts: [
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
      end

      describe 'prompts/get' do
        context 'with valid prompt' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'prompts/get',
              id: 1,
              params: {
                name: 'summarize',
                arguments: { text: 'This is a long text that needs to be summarized.' }
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'successful response', {
            description: 'Summarize the following text',
            messages: [
              {
                role: 'user',
                content: {
                  type: 'text',
                  text: "Please summarize the following text:\n\nThis is a long text that needs to be summarized."
                }
              }
            ]
          }
        end

        context 'with unknown prompt' do
          let(:params) do
            {
              jsonrpc: '2.0',
              method: 'prompts/get',
              id: 1,
              params: {
                name: 'unknown_prompt',
                arguments: {}
              }
            }
          end

          it_behaves_like 'returns content-type json'
          it_behaves_like 'returns http 200'
          it_behaves_like 'error response', -32602, 'Invalid params', 'Unknown prompt: unknown_prompt'
        end
      end

      describe 'method not found' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'nonexistent/method',
            id: 1
          }
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'error response', -32601, 'Method not found', "Method 'nonexistent/method' is not supported"
      end

      describe 'batch requests' do
        let(:params) do
          [
            {
              jsonrpc: '2.0',
              method: 'tools/list',
              id: 1
            },
            {
              jsonrpc: '2.0',
              method: 'resources/list',
              id: 2
            }
          ]
        end

        it 'returns content-type json' do
          make_request
          expect(response.content_type).to include 'application/json'
        end

        it 'returns http 200' do
          make_request
          expect(response).to have_http_status(:ok)
        end

        it 'returns array of responses' do
          make_request
          expect(response.parsed_body).to be_an(Array)
        end

        it 'returns correct number of responses' do
          make_request
          expect(response.parsed_body.length).to eq(2)
        end

        it 'returns correct first response for tools/list' do
          make_request
          expect(response.parsed_body[0].deep_symbolize_keys)
            .to match(
              jsonrpc: '2.0',
              id: 1,
              result: {
                tools: [
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

        it 'returns correct second response for resources/list' do
          make_request
          expect(response.parsed_body[1].deep_symbolize_keys)
            .to match(
              jsonrpc: '2.0',
              id: 2,
              result: {
                resources: [
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
      end

      describe 'requests with nil id' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'tools/list',
            id: nil
          }
        end

        it 'returns content-type json' do
          make_request
          expect(response.content_type).to include 'application/json'
        end

        it 'returns http 200' do
          make_request
          expect(response).to have_http_status(:ok)
        end

        it 'filters out requests with nil id' do
          make_request
          expect(response.parsed_body).to be_nil
        end
      end

      describe 'ping' do
        let(:params) do
          {
            jsonrpc: '2.0',
            method: 'ping',
            id: 1
          }
        end

        it 'returns content-type json' do
          make_request
          expect(response.content_type).to include 'application/json'
        end

        it 'returns http 200' do
          make_request
          expect(response).to have_http_status(:ok)
        end

        it 'returns successful ping response' do
          make_request
          expect(response.parsed_body.deep_symbolize_keys)
            .to match(
              jsonrpc: '2.0',
              id: 1,
              result: {}
            )
        end
      end
    end
  end
end
