# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  subject { build(:api_key) }

  # Associations
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to belong_to(:user).optional }

  # Validations
  it { is_expected.to validate_presence_of(:token) }
  it { is_expected.to validate_uniqueness_of(:token) }

  describe '.active' do
    let!(:active_key)   { create(:api_key, revoked_at: nil, expires_at: nil) }
    let!(:revoked_key)  { create(:api_key, revoked_at: Time.current) }
    let!(:expired_key)  { create(:api_key, expires_at: 1.hour.ago) }

    it 'includes active keys' do
      expect(described_class.active).to include(active_key)
    end

    it 'excludes revoked keys' do
      expect(described_class.active).not_to include(revoked_key)
    end

    it 'excludes expired keys' do
      expect(described_class.active).not_to include(expired_key)
    end
  end

  describe '#revoke!' do
    let(:api_key) { create(:api_key) }

    it 'prefixes token with sk_' do
      expect(api_key.token).to start_with('sk_')
    end

    it 'marks the key as revoked' do
      expect { api_key.revoke! }.to change(api_key, :revoked_at).from(nil)
    end
  end

  describe '#touch_last_used!' do
    it 'updates last_used_at to current time' do
      api_key = create(:api_key, last_used_at: nil)
      expect { api_key.touch_last_used! }.to change(api_key, :last_used_at)
    end
  end
end

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
