# frozen_string_literal: true

FactoryBot.define do
  factory :subscription, class: "ActiveWebhook::Subscription" do
    association :topic, factory: :topic
    disabled_at { nil }
    disabled_reason { nil }
    sequence(:callback_url) { |n| "http://test.com/callback/#{n}" }
    shared_secret { Faker::Lorem.sentence }

    trait :disabed do
      disabled_at { Time.current }
      disabled_reason { "disabled for a good reason" }
    end
  end
end
