# frozen_string_literal: true

module ActiveWebhook
  module Callbacks
    class InvalidCallbackError < StandardError; end
    extend ActiveSupport::Concern

    SUPPORTED_CALLBACKS = %i(created updated deleted).freeze

    class_methods do
      def trigger_webhooks(version: nil, only: nil, except: [], **_options)
        callbacks = if only.nil?
          SUPPORTED_CALLBACKS
        else
          Array.wrap(only).map(&:to_sym)
        end - Array.wrap(except).map(&:to_sym)

        callbacks.each do |callback|
          unless SUPPORTED_CALLBACKS.include? callback
            raise InvalidCallbackError, "Invalid callback: #{callback}. Must be one of #{SUPPORTED_CALLBACKS}."
          end
        end

        after_commit :trigger_created_webhook, on: :create if callbacks.include?(:created)

        after_commit :trigger_updated_webhook, on: :update if callbacks.include?(:updated)

        after_commit :trigger_deleted_webhook, on: :destroy if callbacks.include?(:deleted)
      end
    end

    def trigger_created_webhook
      trigger_webhook(:created)
    end

    def trigger_updated_webhook
      trigger_webhook(:updated) unless previous_changes.empty?
    end

    def trigger_deleted_webhook
      trigger_webhook(:deleted)
    end

    def trigger_webhook(key, version: nil, type: 'resource', **context)
      key = [self.class.name.underscore, key].join("/") unless key.is_a?(String)
      context[:resource_id] ||= id
      context[:resource_type] ||= self.class.name

      ActiveWebhook.trigger(key: key, version: version, type: type, **context)
    end
  end
  ActiveRecord::Base.include ActiveWebhook::Callbacks
end
