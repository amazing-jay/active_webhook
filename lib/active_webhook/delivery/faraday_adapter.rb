# frozen_string_literal: true

require "faraday"

module ActiveWebhook
  module Delivery
    class FaradayAdapter < BaseAdapter
      def status_code
        response.status
      end

      protected

      def deliver!
        Faraday.post(url, body, headers)
      end
    end
  end
end
