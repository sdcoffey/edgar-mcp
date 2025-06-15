# frozen_string_literal: true

module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key
  end

  private

  def authenticate_api_key
    header = request.headers['Authorization']
    return unauthorized('Missing Authorization header') if header.blank?

    Rails.logger.info(header)

    scheme, token = parse_authorization_header(header)
    Rails.logger.info "#{scheme} #{token}"
    return unauthorized('Malformed Authorization header') unless valid_bearer_scheme?(scheme, token)

    api_key = find_active_api_key(token)
    return unauthorized('Invalid or expired API token') if api_key.nil?

    mark_api_key_usage(api_key)
    expose_api_key_context(api_key)
  end

  def parse_authorization_header(header)
    header.split(' ', 2)
  end

  def valid_bearer_scheme?(scheme, token)
    scheme&.casecmp('Bearer')&.zero? && token.present?
  end

  def find_active_api_key(token)
    ApiKey.active.find_by(token: token)
  end

  def mark_api_key_usage(api_key)
    api_key.touch_last_used! if api_key.respond_to?(:touch_last_used!)
  end

  def expose_api_key_context(api_key)
    Current.api_key = api_key
    Current.organization = api_key.organization
    Current.user = api_key.user
  end

  def unauthorized(message)
    error_response = JsonRpc::Error.unauthorized(data: message)
    render pretty_json: error_response, status: :ok
  end
end
