# frozen_string_literal: true

module ActiveWebhook
  module Delivery
    class Configuration
      include ActiveWebhook::Configuration::Base

      define_option :adapter,
                    values: %i[net_http faraday],
                    allow_proc: true

      define_option :max_errors_per_hour,
                    default: 100
    end
  end
end
