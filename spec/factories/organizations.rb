# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }

    trait :with_members do
      after(:create) do |organization|
        create(:organization_membership, organization: organization, role: 'owner')
        create(:organization_membership, organization: organization, role: 'admin')
        create(:organization_membership, organization: organization, role: 'member')
      end
    end

    trait :with_api_keys do
      after(:create) do |organization|
        user = create(:user)
        create(:organization_membership, user: user, organization: organization, role: 'owner')
        create(:api_key, user: user, organization: organization)
      end
    end
  end
end
