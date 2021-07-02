# frozen_string_literal: true

module ActiveWebhook
  module Verification
    class UnsignedAdapter < BaseAdapter
      def call
        {}
      end
    end
  end
end
