# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.not_to allow_value('invalid_email').for(:email) }

    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to have_secure_password }
  end

  describe 'associations' do
    it { is_expected.to have_many(:organization_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:organizations).through(:organization_memberships) }
    it { is_expected.to have_many(:api_keys).dependent(:destroy) }
    it { is_expected.to have_many(:ahoy_visits).dependent(:destroy) }
    it { is_expected.to have_many(:ahoy_events).dependent(:destroy) }
  end

  describe 'callbacks' do
    describe 'before_save :downcase_email' do
      it 'downcases the email before saving' do
        user = build(:user, email: 'USER@EXAMPLE.COM')
        user.save!
        expect(user.email).to eq('user@example.com')
      end

      it 'handles nil email gracefully' do
        user = build(:user, email: nil)
        expect { user.valid? }.not_to raise_error
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_user) { create(:user) }

      it 'returns all users since password_digest is required' do
        expect(described_class.active).to include(active_user)
        expect(described_class.active.count).to eq(described_class.count)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a user with organization' do
      user = create(:user, :with_organization)
      expect(user.organizations.count).to eq(1)
      expect(user.organization_memberships.first.role).to eq('owner')
    end

    it 'creates an admin user' do
      user = create(:user, :admin)
      expect(user.organization_memberships.first.role).to eq('admin')
    end

    it 'creates a member user' do
      user = create(:user, :member)
      expect(user.organization_memberships.first.role).to eq('member')
    end
  end

  describe 'email uniqueness' do
    it 'prevents duplicate emails regardless of case' do
      create(:user, email: 'user@example.com')
      duplicate_user = build(:user, email: 'USER@EXAMPLE.COM')

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'password requirements' do
    it 'requires password on creation' do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'requires password confirmation to match' do
      user = build(:user, password: 'password123', password_confirmation: 'different')
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it 'allows password updates without requiring confirmation' do
      user = create(:user)
      user.password = 'newpassword123'
      user.password_confirmation = nil
      expect(user).to be_valid
    end
  end
end
