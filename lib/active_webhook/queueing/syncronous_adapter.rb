# frozen_string_literal: true

module ActiveWebhook
  module Queueing
    class SyncronousAdapter < BaseAdapter
      def call
        subscriptions.each do |subscription|
          self.class.fulfill_subscription subscription: subscription, **context
        end
        subscriptions.count
      end
    end
  end
end
