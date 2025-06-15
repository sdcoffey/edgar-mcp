# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganizationMembership, type: :model do
  describe 'validations' do
    subject { build(:organization_membership) }

    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[owner admin member]) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }
    let(:owner_membership) { create(:organization_membership, :owner, organization: organization) }
    let(:admin_membership) { create(:organization_membership, :admin, organization: organization) }
    let(:member_membership) { create(:organization_membership, :member, organization: organization) }

    before do
      owner_membership
      admin_membership
      member_membership
    end

    describe '.owners' do
      it 'returns only owner memberships' do
        expect(described_class.owners).to include(owner_membership)
        expect(described_class.owners).not_to include(admin_membership)
        expect(described_class.owners).not_to include(member_membership)
      end
    end

    describe '.admins' do
      it 'returns owner and admin memberships' do
        expect(described_class.admins).to include(owner_membership)
        expect(described_class.admins).to include(admin_membership)
        expect(described_class.admins).not_to include(member_membership)
      end
    end

    describe '.members' do
      it 'returns all memberships' do
        expect(described_class.members).to include(owner_membership)
        expect(described_class.members).to include(admin_membership)
        expect(described_class.members).to include(member_membership)
      end
    end
  end

  describe 'instance methods' do
    describe 'role checking methods' do
      let(:owner_membership) { build(:organization_membership, :owner) }
      let(:admin_membership) { build(:organization_membership, :admin) }
      let(:member_membership) { build(:organization_membership, :member) }

      describe '#owner?' do
        it 'returns true for owner role' do
          expect(owner_membership.owner?).to be true
          expect(admin_membership.owner?).to be false
          expect(member_membership.owner?).to be false
        end
      end

      describe '#admin?' do
        it 'returns true for owner and admin roles' do
          expect(owner_membership.admin?).to be true
          expect(admin_membership.admin?).to be true
          expect(member_membership.admin?).to be false
        end
      end

      describe '#member?' do
        it 'returns true for all valid roles' do
          expect(owner_membership.member?).to be true
          expect(admin_membership.member?).to be true
          expect(member_membership.member?).to be true
        end
      end
    end

    describe 'permission methods' do
      let(:owner_membership) { build(:organization_membership, :owner) }
      let(:admin_membership) { build(:organization_membership, :admin) }
      let(:member_membership) { build(:organization_membership, :member) }

      describe '#can_manage_members?' do
        it 'returns true for admins and owners' do
          expect(owner_membership.can_manage_members?).to be true
          expect(admin_membership.can_manage_members?).to be true
          expect(member_membership.can_manage_members?).to be false
        end
      end

      describe '#can_manage_api_keys?' do
        it 'returns true for admins and owners' do
          expect(owner_membership.can_manage_api_keys?).to be true
          expect(admin_membership.can_manage_api_keys?).to be true
          expect(member_membership.can_manage_api_keys?).to be false
        end
      end
    end
  end

  describe 'factory' do
    it 'creates a valid membership with default member role' do
      membership = build(:organization_membership)
      expect(membership).to be_valid
      expect(membership.role).to eq('member')
    end

    it 'creates an owner membership' do
      membership = build(:organization_membership, :owner)
      expect(membership.role).to eq('owner')
    end

    it 'creates an admin membership' do
      membership = build(:organization_membership, :admin)
      expect(membership.role).to eq('admin')
    end
  end

  describe 'uniqueness constraint' do
    it 'prevents duplicate memberships for same user and organization' do
      user = create(:user)
      organization = create(:organization)

      create(:organization_membership, user: user, organization: organization)
      duplicate_membership = build(:organization_membership, user: user, organization: organization)

      expect(duplicate_membership).not_to be_valid
      expect(duplicate_membership.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user to be member of different organizations' do
      user = create(:user)
      org1 = create(:organization)
      org2 = create(:organization)

      create(:organization_membership, user: user, organization: org1)
      membership2 = build(:organization_membership, user: user, organization: org2)

      expect(membership2).to be_valid
    end
  end

  describe 'role validation' do
    it 'rejects invalid roles' do
      membership = build(:organization_membership, role: 'invalid_role')
      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to include('is not included in the list')
    end

    it 'accepts valid roles' do
      %w[owner admin member].each do |role|
        membership = build(:organization_membership, role: role)
        expect(membership).to be_valid
      end
    end
  end
end
