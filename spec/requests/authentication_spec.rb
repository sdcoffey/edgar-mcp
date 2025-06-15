# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Key Authentication', type: :request do
  describe 'POST /mcp' do
    let(:params) { { jsonrpc: '2.0', method: 'initialize', id: 1 }.to_json }

    context 'when Authorization header is missing' do
      it 'returns HTTP 200' do
        post '/mcp', params: params, headers: { 'content-type': 'application/json' }
        expect(response).to have_http_status(:ok)
      end

      it 'returns unauthorized JSON-RPC error' do
        post '/mcp', params: params, headers: { 'content-type': 'application/json' }
        expect(response.parsed_body.dig('error', 'code')).to eq(-32001)
      end
    end

    context 'when token is invalid' do
      it 'returns HTTP 200' do
        post '/mcp', params: params, headers: {
          'content-type': 'application/json',
          'Authorization' => 'Bearer invalidtoken'
        }
        expect(response).to have_http_status(:ok)
      end

      it 'returns unauthorized JSON-RPC error' do
        post '/mcp', params: params, headers: {
          'content-type': 'application/json',
          'Authorization' => 'Bearer invalidtoken'
        }
        expect(response.parsed_body.dig('error', 'code')).to eq(-32001)
      end
    end

    context 'when token is valid' do
      let(:api_key) { create(:api_key) }

      it 'allows the request' do
        post '/mcp', params: params, headers: {
          'content-type': 'application/json',
          'Authorization' => "Bearer #{api_key.token}"
        }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
