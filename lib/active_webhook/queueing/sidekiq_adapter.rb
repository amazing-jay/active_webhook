# frozen_string_literal: true

require 'sidekiq'

module ActiveWebhook
  module Queueing
    class SidekiqAdapter < BaseAdapter
      class SubscriptionWorker
        include Sidekiq::Worker

        def perform(subscription, hook, context)
          subscription = ActiveWebhook.subscription_model.find_by(id: subscription)
          hook = Hook.from_h(hook.symbolize_keys) unless hook.nil?

          ActiveWebhook.queueing_adapter.fulfill_subscription(
            subscription: subscription,
            hook: hook,
            job_id: jid,
            **context.symbolize_keys
          )
        end
      end

      class TopicWorker
        include Sidekiq::Worker

        def perform(key, version, context)
          ActiveWebhook.queueing_adapter.new(key: key, version: version, **context.symbolize_keys).fulfill_topic
        end
      end

      protected

      def promise_subscription(subscription:, hook:)
        SubscriptionWorker.perform_async subscription.id, hook&.to_h, context
      end

      def promise_topic
        TopicWorker.perform_async key, version, context
      end
    end
  end
end
