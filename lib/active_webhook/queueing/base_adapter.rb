# frozen_string_literal: true

module ActiveWebhook
  module Queueing
    class BaseAdapter < Adapter
      attribute :key, :version, :format_first

      def format_first
        @format_first.nil? ? component_configuration.format_first : @format_first
      end

      # returns count of jobs enqueued
      def call
        return fulfill_topic if format_first

        promise_topic
        1
      end

      def self.build_hook(subscription, **context)
        ActiveWebhook.formatting_adapter.call(subscription: subscription, **context)
      end

      def self.fulfill_subscription(subscription:, hook: nil, **context)
        if ActiveWebhook.enabled?
          ActiveWebhook.delivery_adapter.call(
            subscription: subscription,
            hook: hook || build_hook(subscription, **context),
            **context
          )
        end
        true
      end

      def fulfill_topic
        subscriptions.each do |subscription|
          hook = format_first ? self.class.build_hook(subscription, **context) : nil
          promise_subscription subscription: subscription, hook: hook
        end
        subscriptions.count
      end

      protected

      def self.component_name
        'queueing'
      end

      def promise_subscription(_subscription:, _hook:)
        raise NotImplementedError, '#promise_subscription must be implemented.'
      end

      def promise_topic
        raise NotImplementedError, '#promise_topic must be implemented.'
      end

      def subscriptions
        subscriptions_scope.all
      end

      def subscriptions_scope
        ActiveWebhook.subscription_model.enabled.joins(:topic).includes(:topic).merge(
          ActiveWebhook.topic_model.enabled.with_key(key: key, version: version)
        )
      end
    end
  end
end
