# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_memberships
#
#  id              :bigint           not null, primary key
#  role            :string           default("member"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_org_memberships_on_user_and_org              (user_id,organization_id) UNIQUE
#  index_organization_memberships_on_organization_id  (organization_id)
#  index_organization_memberships_on_role             (role)
#  index_organization_memberships_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class OrganizationMembership < ApplicationRecord
  # Constants
  ROLES = %w[owner admin member].freeze

  # Associations
  belongs_to :user
  belongs_to :organization

  # Validations
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }

  # Scopes
  scope :owners, -> { where(role: 'owner') }
  scope :admins, -> { where(role: %w[owner admin]) }
  scope :members, -> { where(role: ROLES) }

  # Instance methods
  def owner?
    role == 'owner'
  end

  def admin?
    %w[owner admin].include?(role)
  end

  def member?
    ROLES.include?(role)
  end

  def can_manage_members?
    admin?
  end

  def can_manage_api_keys?
    admin?
  end
end
