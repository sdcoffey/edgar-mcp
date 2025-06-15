# frozen_string_literal: true

FactoryBot.define do
  factory :api_key do
    user
    organization
    name { "#{Faker::App.name} API Key" }
    expires_at { 1.year.from_now }

    trait :expired do
      after(:create) do |api_key|
        # rubocop:disable Rails/SkipsModelValidations
        api_key.update_column(:expires_at, 1.day.ago)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    trait :never_expires do
      expires_at { nil }
    end

    trait :recently_used do
      last_used_at { 1.day.ago }
    end

    trait :unused do
      last_used_at { nil }
    end

    trait :short_lived do
      expires_at { 1.hour.from_now }
    end
  end
end
