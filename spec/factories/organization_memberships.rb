# frozen_string_literal: true

FactoryBot.define do
  factory :organization_membership do
    user
    organization
    role { 'member' }

    trait :owner do
      role { 'owner' }
    end

    trait :admin do
      role { 'admin' }
    end

    trait :member do
      role { 'member' }
    end
  end
end
