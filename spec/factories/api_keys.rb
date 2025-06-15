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
FactoryBot.define do
  factory :api_key do
    association :organization
    user { association :user, organization: organization }

    transient do
      token_value { nil }
    end

    after(:build) do |api_key, evaluator|
      # Use provided token if given, else rely on secure_token
      api_key.token = evaluator.token_value if evaluator.token_value.present?
    end
  end
end
