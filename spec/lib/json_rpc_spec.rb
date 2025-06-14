# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonRpc do
  describe JsonRpc::Request do
    describe '#initialize' do
      let(:request) do
        described_class.new(
          id: 1,
          jsonrpc: '2.0',
          method: 'test/method',
          params: { foo: 'bar' }
        )
      end

      it 'sets id attribute correctly' do
        expect(request.id).to eq(1)
      end

      it 'sets jsonrpc attribute correctly' do
        expect(request.jsonrpc).to eq('2.0')
      end

      it 'sets method attribute correctly' do
        expect(request.method).to eq('test/method')
      end

      it 'sets params attribute correctly' do
        expect(request.params).to eq({ foo: 'bar' })
      end
    end

    describe '#valid?' do
      context 'with valid JSON-RPC 2.0 request' do
        it 'returns true' do
          request = described_class.new(
            id: 1,
            jsonrpc: '2.0',
            method: 'test/method',
            params: {}
          )

          expect(request).to be_valid
        end
      end

      context 'with invalid jsonrpc version' do
        it 'returns false' do
          request = described_class.new(
            id: 1,
            jsonrpc: '1.0',
            method: 'test/method',
            params: {}
          )

          expect(request).not_to be_valid
        end
      end

      context 'with nil method' do
        it 'returns false' do
          request = described_class.new(
            id: 1,
            jsonrpc: '2.0',
            method: nil,
            params: {}
          )

          expect(request).not_to be_valid
        end
      end
    end
  end

  describe JsonRpc::Response do
    describe '#initialize' do
      it 'sets id attribute' do
        response = described_class.new(id: 123)
        expect(response.id).to eq(123)
      end
    end

    describe '#as_json' do
      it 'returns basic JSON-RPC response structure' do
        response = described_class.new(id: 456)

        expect(response.as_json).to eq({
                                         jsonrpc: '2.0',
                                         id: 456
                                       })
      end
    end
  end

  describe JsonRpc::Success do
    describe '#initialize' do
      let(:success) { described_class.new(id: 1, result: { data: 'test' }) }

      it 'sets id attribute correctly' do
        expect(success.id).to eq(1)
      end

      it 'sets result attribute correctly' do
        expect(success.result).to eq({ data: 'test' })
      end
    end

    describe '#as_json' do
      it 'returns success response with result' do
        success = described_class.new(id: 2, result: { message: 'ok' })

        expect(success.as_json).to eq({
                                        jsonrpc: '2.0',
                                        id: 2,
                                        result: { message: 'ok' }
                                      })
      end
    end
  end

  describe JsonRpc::Error do
    describe '#initialize' do
      let(:error) do
        described_class.new(
          id: 3,
          error_code: -32601,
          message: 'Method not found',
          data: 'Additional info'
        )
      end

      it 'sets id attribute correctly' do
        expect(error.id).to eq(3)
      end

      it 'sets error_code attribute correctly' do
        expect(error.error_code).to eq(-32601)
      end

      it 'sets message attribute correctly' do
        expect(error.message).to eq('Method not found')
      end

      it 'sets data attribute correctly' do
        expect(error.data).to eq('Additional info')
      end
    end

    describe '#as_json' do
      it 'returns error response structure' do
        error = described_class.new(
          id: 4,
          error_code: -32602,
          message: 'Invalid params',
          data: { detail: 'Missing required parameter' }
        )

        expect(error.as_json).to eq({
                                      jsonrpc: '2.0',
                                      id: 4,
                                      error: {
                                        code: -32602,
                                        message: 'Invalid params',
                                        data: { detail: 'Missing required parameter' }
                                      }
                                    })
      end
    end

    describe '.invalid_request' do
      context 'without data' do
        let(:error) { described_class.invalid_request }

        it 'sets id to nil' do
          expect(error.id).to be_nil
        end

        it 'sets error code to -32600' do
          expect(error.error_code).to eq(-32600)
        end

        it 'sets message to Invalid Request' do
          expect(error.message).to eq('Invalid Request')
        end

        it 'sets data to nil' do
          expect(error.data).to be_nil
        end
      end

      context 'with data' do
        let(:error) { described_class.invalid_request(data: 'Missing field') }

        it 'sets id to nil' do
          expect(error.id).to be_nil
        end

        it 'sets error code to -32600' do
          expect(error.error_code).to eq(-32600)
        end

        it 'sets message to Invalid Request' do
          expect(error.message).to eq('Invalid Request')
        end

        it 'sets data correctly' do
          expect(error.data).to eq('Missing field')
        end
      end
    end

    describe '.parse_error' do
      let(:error) { described_class.parse_error(id: 5, data: 'Malformed JSON') }

      it 'sets id correctly' do
        expect(error.id).to eq(5)
      end

      it 'sets error code to -32700' do
        expect(error.error_code).to eq(-32700)
      end

      it 'sets message to Parse error' do
        expect(error.message).to eq('Parse error')
      end

      it 'sets data correctly' do
        expect(error.data).to eq('Malformed JSON')
      end
    end

    describe '.method_not_found' do
      context 'without method name' do
        let(:error) { described_class.method_not_found(id: 6) }

        it 'sets id correctly' do
          expect(error.id).to eq(6)
        end

        it 'sets error code to -32601' do
          expect(error.error_code).to eq(-32601)
        end

        it 'sets message to Method not found' do
          expect(error.message).to eq('Method not found')
        end

        it 'sets data to nil' do
          expect(error.data).to be_nil
        end
      end

      context 'with method name' do
        let(:error) { described_class.method_not_found(id: 7, method: 'unknown/method') }

        it 'sets id correctly' do
          expect(error.id).to eq(7)
        end

        it 'sets error code to -32601' do
          expect(error.error_code).to eq(-32601)
        end

        it 'sets message to Method not found' do
          expect(error.message).to eq('Method not found')
        end

        it 'sets data with method detail' do
          expect(error.data).to eq("Method 'unknown/method' is not supported")
        end
      end
    end

    describe '.invalid_params' do
      let(:error) { described_class.invalid_params(id: 8, data: 'Missing required field') }

      it 'sets id correctly' do
        expect(error.id).to eq(8)
      end

      it 'sets error code to -32602' do
        expect(error.error_code).to eq(-32602)
      end

      it 'sets message to Invalid params' do
        expect(error.message).to eq('Invalid params')
      end

      it 'sets data correctly' do
        expect(error.data).to eq('Missing required field')
      end
    end
  end
end
