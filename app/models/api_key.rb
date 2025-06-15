# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime
#  last_used_at :datetime
#  token        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_keys_on_token    (token)
#  index_api_keys_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ApiKey < ApplicationRecord
  belongs_to :user
  before_create :generate_token
  before_create :set_expiration
  attr_readonly :token

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def touch_last_used
    update(last_used_at: Time.current)
  end

  private

  def set_expiration
    self.expires_at ||= 1.year.from_now
  end

  def generate_token
    loop do
      self.token = SecureRandom.hex
      break unless ApiKey.exists?(token: token)
    end
  end
end
