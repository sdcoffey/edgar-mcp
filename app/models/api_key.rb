# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id              :bigint           not null, primary key
#  expires_at      :datetime
#  last_used_at    :datetime
#  name            :string           not null
#  token_digest    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_api_keys_on_expires_at                   (expires_at)
#  index_api_keys_on_last_used_at                 (last_used_at)
#  index_api_keys_on_organization_id              (organization_id)
#  index_api_keys_on_token_digest                 (token_digest) UNIQUE
#  index_api_keys_on_user_id                      (user_id)
#  index_api_keys_on_user_id_and_organization_id  (user_id,organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class ApiKeyExpired < StandardError; end

class ApiKey < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :organization

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true
  validate :expiration_date_in_future, if: :expires_at?

  # Callbacks
  before_validation :generate_token_digest

  # Scopes
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where(expires_at: ..Time.current) }

  attr_accessor :plain_token

  # Class methods
  def self.authenticate_with_token(token)
    return nil if token.blank?

    # Use BCrypt hash for secure O(1) database lookup
    token_hash = Digest::SHA256.hexdigest(token)
    token = find_by(token_digest: token_hash)
    return nil if token.blank?

    raise ApiKeyExpired if token.expired?

    token
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def touch_last_used!
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:last_used_at, Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def generate_token_digest
    return if token_digest.present?

    self.plain_token = "sk_#{SecureRandom.hex(32)}"
    self.token_digest = Digest::SHA256.hexdigest(plain_token)
  end

  def expiration_date_in_future
    return unless expires_at.present? && expires_at <= Time.current

    errors.add(:expires_at, 'must be in the future')
  end
end
