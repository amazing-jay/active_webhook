# frozen_string_literal: true

module ActiveWebhook
  module Models
    class Configuration
      include ActiveWebhook::Configuration::Base

      define_option :subscription,
                    default: ActiveWebhook::Subscription

      define_option :topic,
                    default: ActiveWebhook::Topic

      define_option :error_log,
                    default: ActiveWebhook::ErrorLog
    end
  end
end
