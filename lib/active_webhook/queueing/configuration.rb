# frozen_string_literal: true

module ActiveWebhook
  module Queueing
    class Configuration
      include ActiveWebhook::Configuration::Base

      define_option :adapter,
                    values: %i[syncronous sidekiq delayed_job active_job],
                    allow_proc: true

      define_option :format_first, values: [true, false], default: false
    end
  end
end
