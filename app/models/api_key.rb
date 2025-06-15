# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id              :bigint           not null, primary key
#  expires_at      :datetime
#  last_used_at    :datetime
#  revoked_at      :datetime
#  token           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  user_id         :bigint
#
# Indexes
#
#  index_api_keys_on_last_used_at     (last_used_at)
#  index_api_keys_on_organization_id  (organization_id)
#  index_api_keys_on_token            (token) UNIQUE
#  index_api_keys_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#
class ApiKey < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :user, optional: true

  # Token
  has_secure_token :token

  # Validations
  validates :token, presence: true, uniqueness: true

  # Scopes
  scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at.future?)
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end

  # Override class-level token generator used by has_secure_token.
  def self.generate_unique_secure_token(_length = nil)
    "sk_#{SecureRandom.hex(32)}"
  end
end
