# frozen_string_literal: true

FactoryBot.define do
  factory :topic, class: "ActiveWebhook::Topic" do
    sequence(:key) { |n| "key #{n}" }
    sequence(:version) { |n| "3.#{n}" }
    disabled_at { nil }
    disabled_reason { nil }

    trait :disabed do
      disabled_at { Time.current }
      disabled_reason { "disabled for a good reason" }
    end
  end
end
