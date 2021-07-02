# frozen_string_literal: true

module ActiveWebhook
  module Delivery
    class BaseAdapter < Adapter
      attribute :subscription, :hook, :max_errors_per_hour
      attr_accessor :response

      delegate :url, :headers, :body, to: :hook

      def max_errors_per_hour
        @max_errors_per_hour.nil? ? component_configuration.max_errors_per_hour : @max_errors_per_hour
      end

      def call
        ensure_error_log_requirement_is_met!

        wrap_with_log do
          self.response = deliver!

          case status_code
          when 200
            trace "Completed"
          when 410
            trace "Receieved HTTP response code [410] for"
            subscription.destroy!
          else
            raise response.to_s
          end
        end
      rescue StandardError => e
        subscription.error_logs.create!

        raise e # propogate error so queuing adapter has a chance to retry
      end

      def status_code
        raise NotImplementedError, "#deliver! must be implemented."
      end

      def topic
        subscription.topic
      end

      protected

      def self.component_name
        "delivery"
      end

      def deliver!
        raise NotImplementedError, "#deliver! must be implemented."
      end

      def ensure_error_log_requirement_is_met!
        if subscription.ensure_error_log_requirement_is_met! max_errors_per_hour
          trace "Disabled"
        end
      end

      def wrap_with_log
        return if ActiveWebhook.disabled?

        trace("Skipped [subscription disabled]") and return if subscription.disabled?
        trace("Skipped [topic disabled]") and return if topic.disabled?
        trace "Initiated"
        trace "Payload [#{hook.to_h.ai}] for", :debug if ActiveWebhook.logger.level == 0 # log_payloads

        yield

        trace "Completed"

        true
      rescue StandardError => e
        trace "Failed to complete [#{e.message}]", :error

        raise e # propogate error so queuing adapter has a chance to retry
      end

      def trace(msg, level = :info)
        ActiveWebhook.logger.send(level, decorate_log_msg(msg))

        true
      end

      def decorate_log_msg(msg)
        [
          msg,
          "active webhook subscription #{subscription.id}",
          "with(key: #{topic.key}, version: #{topic.version})",
          "to url: #{hook.url} via #{self.class.name}"
        ].join(' ')
      end
    end
  end
end
