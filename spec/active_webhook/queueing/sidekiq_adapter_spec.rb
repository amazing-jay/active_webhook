# frozen_string_literal: true

require "active_webhook/queueing/sidekiq_adapter"

RSpec.describe ActiveWebhook::Queueing::SidekiqAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.queueing.adapter = :sidekiq }
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
      ) do
        expect { ActiveWebhook.trigger(key: key) }.to change {
          ActiveWebhook::Queueing::SidekiqAdapter::TopicWorker.jobs.size
        }.by(1).and change {
          ActiveWebhook::Queueing::SidekiqAdapter::SubscriptionWorker.jobs.size
        }.by(0)
        Sidekiq::Worker.drain_all
      end
    end

    context "with queueing.format_first" do
      before do
        ActiveWebhook.configure { |config| config.queueing.format_first = true }
      end

      it do
        expect_subscription_requests(
          subscription,
          other_subscription,
          versioned_subscription,
          skip: ignored_subscription
        ) do
          expect { ActiveWebhook.trigger(key: key) }.to change {
            ActiveWebhook::Queueing::SidekiqAdapter::TopicWorker.jobs.size
          }.by(0).and change {
            ActiveWebhook::Queueing::SidekiqAdapter::SubscriptionWorker.jobs.size
          }.by(3)
          Sidekiq::Worker.drain_all
        end
      end
    end
  end
end
