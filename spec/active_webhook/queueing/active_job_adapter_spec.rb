# frozen_string_literal: true

require "active_webhook/queueing/active_job_adapter"

RSpec.describe ActiveWebhook::Queueing::ActiveJobAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.queueing.adapter = :active_job }
  end

  describe ".trigger", with_time: :frozen do
    include ActiveJob::TestHelper

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

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
        assert_no_performed_jobs
        ActiveWebhook.trigger(key: key)
        assert_enqueued_jobs 1
        assert_enqueued_with job: ActiveWebhook::Queueing::ActiveJobAdapter::TopicJob
        perform_enqueued_jobs
        assert_enqueued_jobs 3
        assert_enqueued_with job: ActiveWebhook::Queueing::ActiveJobAdapter::SubscriptionJob
        perform_enqueued_jobs
        assert_performed_with job: ActiveWebhook::Queueing::ActiveJobAdapter::SubscriptionJob
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
          assert_no_performed_jobs
          ActiveWebhook.trigger(key: key)
          assert_enqueued_jobs 3
          assert_enqueued_with job: ActiveWebhook::Queueing::ActiveJobAdapter::SubscriptionJob
          perform_enqueued_jobs
          assert_performed_with job: ActiveWebhook::Queueing::ActiveJobAdapter::SubscriptionJob
        end
      end
    end
  end
end
