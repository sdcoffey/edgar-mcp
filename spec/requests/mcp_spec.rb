# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MCP', type: :request do
  let(:api_key) { create(:api_key) }
  let(:headers) { { 'content-type': 'application/json', Authorization: "Bearer #{api_key.token}" } }

  describe 'POST /mcp' do
    subject(:make_request) do
      post '/mcp', params: params.to_json, headers: headers
    end

    let(:params) { {} }
    let(:error_message) { nil }

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

    shared_examples 'invalid request error' do |id = nil|
      it 'returns invalid request error' do
        make_request

        expect(response.parsed_body.deep_symbolize_keys)
          .to match(
            jsonrpc: '2.0',
            id: id,
            error: {
              code: -32600,
              message: 'Invalid Request',
              data: error_message
            }
          )
      end
    end

    describe 'jsonrpc validations' do
      context 'when content-type headers not set' do
        let(:headers) { {} }
        let(:error_message) { "Request must have content type: 'application/json'" }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'invalid request error'
      end

      context 'with incorrect version' do
        let(:headers) { { 'content-type': 'application/json' } }
        let(:params) { { jsonrpc: '1.2' } }
        let(:error_message) { nil }

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
        it_behaves_like 'invalid request error'
      end
    end

    describe 'authentication' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'initialize',
          id: 1
        }
      end

      context 'without an Authorization header' do
        let(:headers) { { 'content-type': 'application/json' } }

        it 'returns an unauthorized status' do
          make_request
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns a meaningful error message' do
          make_request
          body = response.parsed_body
          expect(body['error']['data']).to eq('Authorization header is missing')
        end
      end

      context 'with an invalid API key' do
        let(:headers) { { 'content-type': 'application/json', Authorization: 'Bearer invalid' } }

        it 'returns an unauthorized status' do
          make_request
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns a meaningful error message' do
          make_request
          body = response.parsed_body
          expect(body['error']['data']).to eq('Invalid API Key')
        end
      end

      context 'with an expired API key' do
        let(:api_key) { create(:api_key, expires_at: 1.day.ago) }
        let(:headers) { { 'content-type': 'application/json', Authorization: "Bearer #{api_key.token}" } }

        it 'returns an unauthorized status' do
          make_request
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns a meaningful error message' do
          make_request
          body = response.parsed_body
          expect(body['error']['data']).to eq('Invalid API Key')
        end
      end
    end

    describe 'MCP protocol methods' do
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

        it 'returns a successful response with user and org info' do
          make_request
          expected_result = {
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
            user: {
              id: api_key.user.id,
              email: api_key.user.email
            },
            organization: {
              id: api_key.user.organization.id,
              name: api_key.user.organization.name
            }
          }
          expect(response.parsed_body.deep_symbolize_keys).to match(
            jsonrpc: '2.0',
            id: 1,
            result: expected_result
          )
        end

        it_behaves_like 'returns content-type json'
        it_behaves_like 'returns http 200'
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
