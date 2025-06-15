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
require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'callbacks' do
    subject(:api_key) { build(:api_key, user: user, token: nil, expires_at: nil) }

    it 'generates a token before creation' do
      expect { api_key.save! }.to change(api_key, :token).from(nil)
    end

    it 'sets an expiration date before creation' do
      expect { api_key.save! }.to change(api_key, :expires_at).from(nil)
    end

    it 'sets the expiration date to one year from now' do
      api_key.save!
      expect(api_key.expires_at).to be_within(1.minute).of(1.year.from_now)
    end
  end

  describe '#expired?' do
    it 'returns true if the key is expired' do
      api_key = create(:api_key, user: user, expires_at: 1.day.ago)
      expect(api_key.expired?).to be true
    end

    it 'returns false if the key is not expired' do
      api_key = create(:api_key, user: user, expires_at: 1.day.from_now)
      expect(api_key.expired?).to be false
    end

    it 'returns false if expires_at is nil' do
      api_key = create(:api_key, user: user, expires_at: nil)
      expect(api_key.expired?).to be false
    end
  end

  describe '.active' do
    it 'includes keys that have not expired' do
      active_key = create(:api_key, user: user, expires_at: 1.day.from_now)
      expect(described_class.active).to include(active_key)
    end

    it 'includes keys with no expiration date' do
      active_key = create(:api_key, user: user, expires_at: nil)
      expect(described_class.active).to include(active_key)
    end

    it 'excludes keys that have expired' do
      expired_key = create(:api_key, user: user, expires_at: 1.day.ago)
      expect(described_class.active).not_to include(expired_key)
    end
  end

  describe '#touch_last_used' do
    it 'updates the last_used_at timestamp' do
      api_key = create(:api_key, user: user, last_used_at: nil)
      expect { api_key.touch_last_used }.to(change { api_key.last_used_at })
    end
  end

  describe 'token' do
    it 'is readonly' do
      api_key = create(:api_key, user: user)
      expect { api_key.update(token: 'new-token') }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end
end
