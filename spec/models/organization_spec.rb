# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_name  (name)
#
require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { build(:organization) }

  # Associations
  it { is_expected.to have_many(:users).dependent(:destroy) }
  it { is_expected.to have_many(:api_keys).dependent(:destroy) }

  # Validations
  it { is_expected.to validate_presence_of(:name) }
end
