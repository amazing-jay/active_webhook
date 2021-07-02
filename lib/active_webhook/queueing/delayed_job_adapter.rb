# frozen_string_literal: true

require "delayed_job"

module ActiveWebhook
  module Queueing
    class DelayedJobAdapter < BaseAdapter
      protected

      def promise_subscription(subscription:, hook:)
        ActiveWebhook.queueing_adapter.fulfill_subscription(
          subscription: subscription,
          hook: hook,
          # NOTE: not implemented yet;
          # SEE: https://stackoverflow.com/questions/21590798/referencing-delayed-job-job-id-from-within-the-job-task
          # job_id: ???
          **context
        )
      end
      handle_asynchronously :promise_subscription

      def promise_topic
        fulfill_topic
      end
      handle_asynchronously :promise_topic
    end
  end
end
