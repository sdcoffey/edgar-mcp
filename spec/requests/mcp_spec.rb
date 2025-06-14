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

    shared_examples 'http 200' do
      it 'has content-type json' do
        make_request
        expect(response.content_type).to include 'application/json'
      end

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

    describe 'jsonrpc validations' do
      context 'when content-type headers not set' do
        let(:error_message) { "Request must have content type: 'application/json'" }

        it_behaves_like 'http 200'
        it_behaves_like 'invalid request error'
      end

      context 'with incorrect version' do
        let(:headers) { { 'content-type': 'application/json' } }
        let(:params) { { jsonrpc: '1.2' } }
        let(:error_message) { nil }

        it_behaves_like 'http 200'
        it_behaves_like 'invalid request error'
      end
    end
  end
end
