# frozen_string_literal: true

module ActiveWebhook
  module Verification
    class Configuration
      include ActiveWebhook::Configuration::Base

      define_option :adapter,
                    values: %i[unsigned hmac_sha256],
                    allow_proc: true
    end
  end
end
