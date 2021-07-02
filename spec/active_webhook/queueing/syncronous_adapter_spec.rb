# frozen_string_literal: true

require "active_webhook/queueing/syncronous_adapter"

RSpec.describe ActiveWebhook::Queueing::SyncronousAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.queueing.adapter = :syncronous }
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

    context "with queueing.format_first" do
      before do
        ActiveWebhook.configure { |config| config.queueing.format_first = true }
      end

      it "does not change"do
        expect_subscription_requests(
          subscription,
          other_subscription,
          versioned_subscription,
          skip: ignored_subscription
        ) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
      end
    end
  end
end
