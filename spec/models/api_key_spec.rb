# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  describe 'validations' do
    subject(:api_key) { build(:api_key) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it 'validates uniqueness of token_digest' do
      create(:api_key)
      expect(api_key).to validate_uniqueness_of(:token_digest)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
  end

  describe 'callbacks' do
    describe 'before_validation :generate_token_digest' do
      it 'generates token_digest before validation' do
        api_key = build(:api_key, token_digest: nil)
        api_key.valid?
        expect(api_key.token_digest).to be_present
        expect(api_key.plain_token).to be_present
      end

      it 'does not regenerate token_digest if already present' do
        api_key = build(:api_key)
        api_key.valid? # This triggers the callback and generates token_digest
        original_digest = api_key.token_digest
        api_key.valid? # This should not regenerate
        expect(api_key.token_digest).to eq(original_digest)
      end
    end
  end

  describe 'scopes' do
    let!(:active_key) { create(:api_key, expires_at: 1.day.from_now) }
    let!(:expired_key) { create(:api_key, :expired) }
    let!(:never_expires_key) { create(:api_key, :never_expires) }

    describe '.active' do
      it 'returns non-expired keys' do
        expect(described_class.active).to include(active_key)
        expect(described_class.active).to include(never_expires_key)
        expect(described_class.active).not_to include(expired_key)
      end
    end

    describe '.expired' do
      it 'returns expired keys' do
        expect(described_class.expired).to include(expired_key)
        expect(described_class.expired).not_to include(active_key)
        expect(described_class.expired).not_to include(never_expires_key)
      end
    end
  end

  describe 'class methods' do
    describe '.authenticate_with_token' do
      let(:api_key) { create(:api_key) }
      let(:token) { api_key.plain_token }

      it 'finds active api key by valid token' do
        found_key = described_class.authenticate_with_token(token)
        expect(found_key).to eq(api_key)
      end

      it 'returns nil for invalid token' do
        found_key = described_class.authenticate_with_token('invalid_token')
        expect(found_key).to be_nil
      end

      it 'returns nil for blank token' do
        found_key = described_class.authenticate_with_token('')
        expect(found_key).to be_nil
      end

      it 'raises ApiKeyExpired for expired keys' do
        expired_key = create(:api_key, :expired)
        expect { described_class.authenticate_with_token(expired_key.plain_token) }
          .to raise_error(ApiKeyExpired)
      end
    end
  end

  describe 'instance methods' do
    let(:api_key) { create(:api_key) }
    let(:token) { api_key.plain_token }

    describe '#expired?' do
      it 'returns false for keys without expiration' do
        key = create(:api_key, :never_expires)
        expect(key.expired?).to be false
      end

      it 'returns false for keys not yet expired' do
        key = create(:api_key, expires_at: 1.day.from_now)
        expect(key.expired?).to be false
      end

      it 'returns true for expired keys' do
        key = create(:api_key, :expired)
        expect(key.expired?).to be true
      end
    end

    describe '#active?' do
      it 'returns true for non-expired keys' do
        key = create(:api_key, expires_at: 1.day.from_now)
        expect(key.active?).to be true
      end

      it 'returns false for expired keys' do
        key = create(:api_key, :expired)
        expect(key.active?).to be false
      end
    end

    describe '#touch_last_used!' do
      it 'updates last_used_at timestamp' do
        api_key = create(:api_key, last_used_at: nil)
        expect { api_key.touch_last_used! }.to change(api_key, :last_used_at).from(nil)
      end

      it 'does not trigger callbacks' do
        api_key = create(:api_key)
        allow(api_key).to receive(:valid?)
        api_key.touch_last_used!
        expect(api_key).not_to have_received(:valid?)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid api key' do
      api_key = build(:api_key)
      expect(api_key).to be_valid
    end

    it 'creates an expired api key' do
      api_key = create(:api_key, :expired)
      expect(api_key.expired?).to be true
    end

    it 'creates a never expiring api key' do
      api_key = create(:api_key, :never_expires)
      expect(api_key.expires_at).to be_nil
      expect(api_key.expired?).to be false
    end

    it 'creates a recently used api key' do
      api_key = create(:api_key, :recently_used)
      expect(api_key.last_used_at).to be_present
    end

    it 'creates an unused api key' do
      api_key = create(:api_key, :unused)
      expect(api_key.last_used_at).to be_nil
    end
  end

  describe 'token generation' do
    it 'generates unique tokens' do
      key1 = create(:api_key)
      key2 = create(:api_key)

      expect(key1.token_digest).not_to eq(key2.token_digest)
      expect(key1.plain_token).not_to eq(key2.plain_token)
    end

    it 'stores token digest, not plain token' do
      api_key = create(:api_key)
      expect(api_key.token_digest).to be_present
      expect(api_key.token_digest).not_to eq(api_key.plain_token)
    end

    it 'generates 64-character hex tokens' do
      api_key = create(:api_key)
      expect(api_key.plain_token).to match(/\A[a-f0-9]{64}\z/)
    end
  end

  describe 'expiration validation' do
    it 'allows future expiration dates' do
      api_key = build(:api_key, expires_at: 1.day.from_now)
      expect(api_key).to be_valid
    end

    it 'allows nil expiration date' do
      api_key = build(:api_key, expires_at: nil)
      expect(api_key).to be_valid
    end

    it 'rejects past expiration dates' do
      api_key = build(:api_key, expires_at: 1.day.ago)
      expect(api_key).not_to be_valid
      expect(api_key.errors[:expires_at]).to include('must be in the future')
    end
  end

  describe 'security considerations' do
    it 'plain_token is cleared after creation' do
      api_key = create(:api_key)
      # Simulate reload from database
      reloaded_key = described_class.find(api_key.id)
      expect(reloaded_key.plain_token).to be_blank
    end

    it 'token_digest is irreversible and salted' do
      api_key = create(:api_key)
      token = api_key.plain_token

      # Should not be able to reverse the digest
      expect(api_key.token_digest).not_to include(token)
      expect(api_key.token_digest.length).to be > 50 # BCrypt hashes are long
    end

    it 'same token produces different digests due to salt' do
      token = 'test_token_123'
      digest1 = BCrypt::Password.create(token)
      digest2 = BCrypt::Password.create(token)

      # BCrypt includes random salt so same input produces different hashes
      expect(digest1).not_to eq(digest2)
      # But both should validate the same token
      expect(BCrypt::Password.new(digest1) == token).to be true
      expect(BCrypt::Password.new(digest2) == token).to be true
    end
  end
end
