# frozen_string_literal: true

module ActiveWebhook
  module Formatting
    class Configuration
      include ActiveWebhook::Configuration::Base

      define_option :adapter,
                    values: %i[json url_encoded],
                    allow_proc: true

      define_option :custom_header_prefix

      define_option :user_agent,
                    default: ActiveWebhook::IDENTIFIER
    end
  end
end
