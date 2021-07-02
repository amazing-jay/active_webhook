# frozen_string_literal: true

module ActiveWebhook
  module Models
    module TopicAdditions
      extend ActiveSupport::Concern

      included do
        self.table_name = "active_webhook_topics"

        scope :enabled, -> { where(disabled_at: nil) }
        scope :with_key, lambda { |key:, version: nil|
          scope = where(key: key)
          scope = scope.where(version: version) if version.present?
          scope
        }

        def self.last_with_key(key)
          where(key: key).order(id: :desc).first
        end

        before_validation :set_valid_version
        validates :key, presence: true
        validates :version, presence: true, uniqueness: { scope: :key }
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

      protected

      def set_valid_version
        return if version.present?

        last_with_key = self.class.last_with_key key
        versions = last_with_key&.version.to_s.split(".")
        versions = [0] if versions.empty?
        version = versions.pop
        versions << version.to_i + 1

        self.version = versions.join(".")
      end
    end
  end
end
