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
FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
  end
end
