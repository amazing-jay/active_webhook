# frozen_string_literal: true

require "active_webhook/delivery/faraday_adapter"

RSpec.describe ActiveWebhook::Delivery::FaradayAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.delivery.adapter = :faraday }
  end

  describe ".trigger", with_time: :frozen do
    let(:key) { "abcdef" }
    let(:topic) { create :topic, key: key }
    let(:versioned_topic) { create :topic, key: key }
    let(:subscription) { create :subscription, topic: topic }
    let(:other_subscription) { create :subscription, topic: topic }
    let(:versioned_subscription) { create :subscription, topic: versioned_topic }
    let(:ignored_subscription) { create :subscription }

    it do
      expect_subscription_requests(
        subscription,
        other_subscription,
        versioned_subscription,
        skip: ignored_subscription
      ) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
    end
  end
end
