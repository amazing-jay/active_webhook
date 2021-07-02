# frozen_string_literal: true

require "active_webhook/queueing/delayed_job_adapter"

RSpec.describe ActiveWebhook::Queueing::DelayedJobAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.queueing.adapter = :delayed_job }
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
        expect do
          ActiveWebhook.trigger(key: key)
        end.to change(Delayed::Job, :count).by(1)

        expect do
          Delayed::Worker.new.work_off
        end.to change(Delayed::Job, :count).by(-1)
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
          expect do
            ActiveWebhook.trigger(key: key)
          end.to change(Delayed::Job, :count).by(3)

          expect do
            Delayed::Worker.new.work_off
          end.to change(Delayed::Job, :count).by(-3)
        end
      end
    end
  end
end
