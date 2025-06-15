# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_organization do
      after(:create) do |user|
        organization = create(:organization)
        create(:organization_membership, user: user, organization: organization, role: 'owner')
      end
    end

    trait :admin do
      after(:create) do |user|
        organization = create(:organization)
        create(:organization_membership, user: user, organization: organization, role: 'admin')
      end
    end

    trait :member do
      after(:create) do |user|
        organization = create(:organization)
        create(:organization_membership, user: user, organization: organization, role: 'member')
      end
    end
  end
end
