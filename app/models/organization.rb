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
class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  validates :name, presence: true
end
