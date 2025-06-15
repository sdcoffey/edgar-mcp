# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'validations' do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:organization_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:organization_memberships) }
    it { is_expected.to have_many(:api_keys).dependent(:destroy) }
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:owner) { create(:user) }
    let(:admin) { create(:user) }
    let(:member) { create(:user) }

    before do
      create(:organization_membership, user: owner, organization: organization, role: 'owner')
      create(:organization_membership, user: admin, organization: organization, role: 'admin')
      create(:organization_membership, user: member, organization: organization, role: 'member')
    end

    describe '#owners' do
      it 'returns users with owner role' do
        expect(organization.owners).to include(owner)
        expect(organization.owners).not_to include(admin)
        expect(organization.owners).not_to include(member)
      end
    end

    describe '#admins' do
      it 'returns users with owner or admin roles' do
        expect(organization.admins).to include(owner)
        expect(organization.admins).to include(admin)
        expect(organization.admins).not_to include(member)
      end
    end

    describe '#members' do
      it 'returns all users regardless of role' do
        expect(organization.members).to include(owner)
        expect(organization.members).to include(admin)
        expect(organization.members).to include(member)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid organization' do
      organization = build(:organization)
      expect(organization).to be_valid
    end

    it 'creates an organization with members' do
      organization = create(:organization, :with_members)
      expect(organization.users.count).to eq(3)
      expect(organization.owners.count).to eq(1)
      expect(organization.admins.count).to eq(2) # owner + admin
      expect(organization.members.count).to eq(3) # all roles
    end

    it 'creates an organization with api keys' do
      organization = create(:organization, :with_api_keys)
      expect(organization.api_keys.count).to eq(1)
      expect(organization.users.count).to eq(1)
    end
  end

  describe 'cascading deletes' do
    let(:organization) { create(:organization) }
    let(:user) { create(:user) }

    before do
      create(:organization_membership, user: user, organization: organization)
      create(:api_key, user: user, organization: organization)
    end

    it 'deletes associated memberships when organization is destroyed' do
      expect { organization.destroy! }.to change(OrganizationMembership, :count).by(-1)
    end

    it 'deletes associated api keys when organization is destroyed' do
      expect { organization.destroy! }.to change(ApiKey, :count).by(-1)
    end
  end

  describe 'name uniqueness' do
    it 'allows organizations with the same name' do
      create(:organization, name: 'Acme Corp')
      duplicate_org = build(:organization, name: 'Acme Corp')

      expect(duplicate_org).to be_valid
    end
  end
end
