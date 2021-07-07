# frozen_string_literal: true

require 'json'

module ActiveWebhook
  module Formatting
    class JSONAdapter < BaseAdapter
      protected

      def content_type
        'application/json'
      end

      def encoded_data
        data.to_json
      end
    end
  end
end
