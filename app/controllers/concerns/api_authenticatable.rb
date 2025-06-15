# frozen_string_literal: true

module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user, :current_organization, :current_api_key
  end

  private

  def authenticate_api_key!
    api_key = extract_api_key_from_request

    unless api_key
      render_authentication_error('Missing API key')
      return
    end

    @current_api_key = ApiKey.authenticate_with_token(api_key)
    if @current_api_key.blank?
      render_authentication_error('Invalid API key')
    else

      @current_user = @current_api_key.user
      @current_organization = @current_api_key.organization

      # Update last_used_at timestamp
      @current_api_key.touch_last_used!
    end
  rescue ApiKeyExpired
    render_authentication_error('API key has expired')
  end

  def extract_api_key_from_request
    return if request.authorization.blank?

    token = request.authorization.split.last if request.authorization.start_with?('Bearer ')
    token.presence
  end

  def render_authentication_error(message)
    error_response = JsonRpc::Error.new(
      id: nil,
      error_code: -32001, # Custom error code for authentication
      message: 'Authentication Required',
      data: message
    )

    render pretty_json: error_response, status: :unauthorized
  end

  def authenticated?
    current_api_key.present? && current_api_key.active?
  end

  def require_admin_access!
    return if current_user_is_admin?

    render_authorization_error('Admin access required')
  end

  def current_user_is_admin?
    return false unless current_user && current_organization

    membership = current_user.organization_memberships
                             .find_by(organization: current_organization)
    membership&.admin?
  end

  def render_authorization_error(message)
    error_response = JsonRpc::Error.new(
      id: nil,
      error_code: -32002, # Custom error code for authorization
      message: 'Authorization Required',
      data: message
    )

    render pretty_json: error_response, status: :forbidden
  end
end
