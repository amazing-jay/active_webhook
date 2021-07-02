# frozen_string_literal: true

require "rubygems"
require "base64"
require "openssl"
require "active_support/security_utils"

module ActiveWebhook
  module Verification
    class HMACSHA256Adapter < BaseAdapter
      def signature
        Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, data))
      end

      def strategy
        "Hmac-SHA256"
      end
    end
  end
end
