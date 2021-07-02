# frozen_string_literal: true

module ActiveWebhook
  module Models
    module SubscriptionAdditions
      extend ActiveSupport::Concern

      included do
        self.table_name = "active_webhook_subscriptions"

        scope :enabled, -> { where(disabled_at: nil) }

        validates_presence_of :topic
        validates :callback_url, format: {
          with: URI::DEFAULT_PARSER.make_regexp(['http', 'https']),
          message: 'is not a valid URL'
        }

        before_save :set_disabled_reason
        after_save :clean_error_log
      end

      def set_disabled_reason
        self.disabled_reason = nil if self.disabled_at.nil?
      end

      def clean_error_log
        error_logs.delete_all if previous_changes.key?(:disabled_at) && enabled?
      end

      def ensure_error_log_requirement_is_met! max_errors_per_hour
        return false if disabled?

        if max_errors_per_hour.present? && error_logs.where('created_at > ?', 1.hour.ago).count > max_errors_per_hour
          disable! "Exceeded max_errors_per_hour of (#{max_errors_per_hour})"
          return true
        end
      rescue StandardError
        # intentionally squash errors so that we don't end up in a loop where queue adapter retries and locks table
        false
      end

      def disable(reason = nil)
        self.disabled_at = Time.current
        self.disabled_reason = reason
      end

      def disable!(reason = nil)
        disable reason
        save!
      end

      def enable
        self.disabled_at = nil
        self.disabled_reason = nil
      end

      def enable!
        enable
        save!
      end

      def disabled?
        !enabled?
      end

      def enabled?
        disabled_at.nil?
      end
    end
  end
end
