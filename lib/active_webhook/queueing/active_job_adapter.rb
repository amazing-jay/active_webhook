# frozen_string_literal: true

module ActiveWebhook
  module Queueing
    class ActiveJobAdapter < BaseAdapter
      class SubscriptionJob < ApplicationJob
        queue_as :low_priority

        def perform(subscription, hook, context)
          context.symbolize_keys!
          hook = Hook.from_h(hook.symbolize_keys) unless hook.nil?

          ActiveWebhook.queueing_adapter.fulfill_subscription(
            subscription: subscription,
            hook: hook,
            job_id: job_id,
            **context
          )
        end
      end

      class TopicJob < ApplicationJob
        queue_as :low_priority

        def perform(key, version, context)
          context.symbolize_keys!

          ActiveWebhook.queueing_adapter.new(key: key, version: version, **context).fulfill_topic
        end
      end

      protected

      def promise_subscription(subscription:, hook:)
        SubscriptionJob.perform_later subscription, hook&.to_h, context
      end

      def promise_topic
        TopicJob.perform_later key, version, context
      end
    end
  end
end
