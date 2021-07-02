# frozen_string_literal: true

module ActiveWebhook
  module Formatting
    class BaseAdapter < Adapter
      attribute :subscription, :job_id, :type

      def call
        Hook.new url, headers, body
      end

      protected

      def self.component_name
        "formatting"
      end

      def url
        subscription.callback_url
      end

      def headers
        default_headers.stringify_keys.merge(custom_headers.transform_keys { |key| "#{prefix}-#{key}" })
      end

      def body
        encoded_data
      end

      def encoded_data
        raise NotImplementedError, "#encoded_data must be implemented."
      end

      def content_type
        raise NotImplementedError, "#content_type must be implemented."
      end

      def default_headers
        h = {
          "Content-Type": content_type,
          "User-Agent": component_configuration.user_agent
        }
        h['Origin'] = ActiveWebhook.origin.to_s if ActiveWebhook.origin.present?
        h
      end

      def custom_headers
        h = signature_headers.merge(
          Time: time.to_s,
          Topic: topic.key,
          'Topic-Version': topic.version,
          'Webhook-Type': type.presence || "event"
        )
        h['Webhook-Id'] = job_id if job_id.present?
        h
      end

      def data
        context[:data].presence || resource&.as_json || default_data
      end

      def default_data
        result = { data: {} }

        if resource_id || resource_type
          result[:data] = {}
          result[:data][:id] = resource_id if resource_id
          result[:data][:type] = resource_type if resource_type
        end

        result
      end

      def resource_id
        context[:resource_id]
      end

      def resource_type
        context[:resource_type]
      end

      def resource
        resource_type.constantize.find_by(id: resource_id) if type == "resource" && resource_id && resource_type
      rescue StandardError
        nil
      end

      def topic
        subscription.topic
      end

      def prefix
        @prefix ||= begin
          x = ["X"]
          x << component_configuration.custom_header_prefix
          x.compact.join("-")
        end
      end

      def time
        context[:time] || Time.current
      end

      def signature_headers
        ActiveWebhook.verification_adapter.call secret: subscription.shared_secret.to_s, data: body.to_s
      end
    end
  end
end
