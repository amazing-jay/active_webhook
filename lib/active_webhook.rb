# frozen_string_literal: true

require 'active_record'
require 'memoist'

require 'active_webhook/adapter'
require 'active_webhook/delivery/base_adapter'
require 'active_webhook/formatting/base_adapter'
require 'active_webhook/queueing/base_adapter'
require 'active_webhook/verification/base_adapter'

require 'active_webhook/models/error_log_additions'
require 'active_webhook/models/subscription_additions'
require 'active_webhook/models/topic_additions'

require 'active_webhook/callbacks'
require 'active_webhook/hook'
require 'active_webhook/error_log'
require 'active_webhook/logger'
require 'active_webhook/subscription'
require 'active_webhook/topic'
require 'active_webhook/version'

module ActiveWebhook
  class InvalidAdapterError < StandardError; end

  IDENTIFIER = "Active Webhook v#{VERSION}"

  # IDENTIFIER must be defined first
  require 'active_webhook/configuration'

  class << self
    attr_writer :enabled

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)

      configuration.after_configure
    end

    def logger
      defined?(Rails) ? Rails.logger : (@logger ||= Logger.new($stdout))
    end

    def subscription_model
      configuration.models.subscription
    end

    def topic_model
      configuration.models.topic
    end

    def origin
      return @@origin if defined? @@origin

      @@origin = (Rails.application.config.action_mailer.default_url_options[:host] if defined?(Rails))
    rescue StandardError
      @@origin = ''
    end

    # TODO: change the next 4 methods to use memoized thread safe class var rather than configuration.enabled
    def enabled?
      configuration.enabled
    end

    def disabled?
      !enabled?
    end

    def enable
      state = enabled?
      configuration.enabled = true
      value = yield
    ensure
      configuration.enabled = state
      value
    end

    def disable
      state = enabled?
      configuration.enabled = false
      value = yield
    ensure
      configuration.enabled = state
      value
    end

    Configuration::ADAPTERS.each do |type|
      define_method "#{type}_adapter" do
        fetch_adapter type, configuration.send(type).send('adapter')
      end
    end

    def trigger(key:, version: nil, **context)
      queueing_adapter.call(key: key, version: version, **context) if enabled?
      true
    end

    protected

    def fetch_adapter(type, adapter)
      if adapter.is_a?(Symbol) || adapter.is_a?(String)
        adapter = begin
          @adapters ||= {}
          @adapters[type] ||= {}
          @adapters[type][adapter.to_sym] = begin
            path = "active_webhook/#{type}/#{adapter}_adapter"
            require path
            const_name = path.camelize
            ['http', 'sha', 'hmac', 'json', 'url'].each { |acronym| const_name.gsub!(acronym.camelize, acronym.upcase) }
            const_name.constantize
          end
        end
      end

      raise InvalidAdapterError unless adapter.respond_to?(:call)

      adapter
    end
  end
end
