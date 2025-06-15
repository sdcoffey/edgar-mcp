# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiAuthenticatable, type: :controller do
  controller(ApplicationController) do
    include described_class

    skip_before_action :verify_authenticity_token
    before_action :authenticate_api_key!

    def index
      render json: {
        message: 'success',
        user: current_user.name,
        organization: current_organization.name,
        api_key: current_api_key.name
      }
    end

    def admin_only
      require_admin_access!
      return if performed? # Stop execution if response was already rendered

      render json: { message: 'admin access granted' }
    end
  end

  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:api_key) { create(:api_key, user: user, organization: organization) }
  let(:token) { api_key.plain_token }

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'admin_only' => 'anonymous#admin_only'
    end
  end

  describe '#authenticate_api_key!' do
    context 'with valid API key in Authorization header' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
      end

      it 'sets current_user, current_organization, and current_api_key' do
        get :index
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response['user']).to eq(user.name)
        expect(json_response['organization']).to eq(organization.name)
        expect(json_response['api_key']).to eq(api_key.name)
      end

      it 'updates last_used_at timestamp' do
        expect { get :index }.to change { api_key.reload.last_used_at }.from(nil)
      end
    end

    context 'with no API key' do
      it 'returns authentication error' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        json_response = response.parsed_body
        expect(json_response['error']['code']).to eq(-32001)
        expect(json_response['error']['message']).to eq('Authentication Required')
        expect(json_response['error']['data']).to eq('Missing API key')
      end
    end

    context 'with invalid API key' do
      before do
        request.headers['Authorization'] = 'Bearer invalid-token'
      end

      it 'returns authentication error' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        json_response = response.parsed_body
        expect(json_response['error']['code']).to eq(-32001)
        expect(json_response['error']['message']).to eq('Authentication Required')
        expect(json_response['error']['data']).to eq('Invalid API key')
      end
    end

    context 'with expired API key' do
      let(:expired_api_key) { create(:api_key, :expired, user: user, organization: organization) }

      before do
        request.headers['Authorization'] = "Bearer #{expired_api_key.plain_token}"
      end

      it 'returns authentication error' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        json_response = response.parsed_body
        expect(json_response['error']['code']).to eq(-32001)
        expect(json_response['error']['message']).to eq('Authentication Required')
        expect(json_response['error']['data']).to eq('API key has expired')
      end
    end
  end

  describe '#require_admin_access!' do
    before do
      request.headers['Authorization'] = "Bearer #{token}"
    end

    context 'when user is admin' do
      let(:membership) { create(:organization_membership, :admin, user: user, organization: organization) }

      before { membership }

      it 'allows access' do
        get :admin_only
        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response['message']).to eq('admin access granted')
      end
    end

    context 'when user is owner' do
      let(:membership) { create(:organization_membership, :owner, user: user, organization: organization) }

      before { membership }

      it 'allows access' do
        get :admin_only
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is member' do
      let(:membership) { create(:organization_membership, :member, user: user, organization: organization) }

      before { membership }

      it 'returns authorization error' do
        get :admin_only
        expect(response).to have_http_status(:forbidden)

        json_response = response.parsed_body
        expect(json_response['error']['code']).to eq(-32002)
        expect(json_response['error']['message']).to eq('Authorization Required')
        expect(json_response['error']['data']).to eq('Admin access required')
      end
    end
  end

  describe '#authenticated?' do
    subject { controller.send(:authenticated?) }

    context 'with valid authentication' do
      before do
        controller.instance_variable_set(:@current_api_key, api_key)
      end

      it { is_expected.to be true }
    end

    context 'with expired API key' do
      let(:expired_api_key) { create(:api_key, :expired) }

      before do
        controller.instance_variable_set(:@current_api_key, expired_api_key)
      end

      it { is_expected.to be false }
    end

    context 'with no API key' do
      it { is_expected.to be false }
    end
  end
end
