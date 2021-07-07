# frozen_string_literal: true

require 'addressable/uri'

module ActiveWebhook
  module Formatting
    class URLEncodedAdapter < BaseAdapter
      protected

      def self.compact(h)
        h.delete_if do |_k, v|
          v = compact(v) if v.respond_to?(:each)
          v.nil? || v.empty?
        end
      end

      def content_type
        'application/x-www-form-urlencoded'
      end

      def encoded_data
        uri = Addressable::URI.new
        uri.query_values = self.class.compact(data)
        uri.query
      end
    end
  end
end
