# frozen_string_literal: true

module ActiveWebhook
  class Configuration
    class InvalidOptionError < StandardError
      def initialize(option, value, values)
        @option = option
        @values = values
        msg = "Invalid option for #{option}: #{value}. Must be one of #{values}."
        super(msg)
      end
    end

    module Base
      extend ActiveSupport::Concern

      def initialize
        (self.class.instance_variable_get(:@components) || []).each do |component_name|
          component = "#{self.class.name.deconstantize}::#{component_name.to_s.camelize}::Configuration"
          component = component.constantize.new
          instance_variable_set "@#{component_name}", component
        end

        (self.class.instance_variable_get(:@options) || []).each do |option, option_definition|
          send "#{option}=", option_definition[:default]
        end
      end

      class_methods do
        protected

        # TODO: consider changing so that all options accept a proc
        #  q: does the proc run every time the option is asked? seems inefficent
        def define_option(option, values: [], default: nil, allow_nil: false, allow_proc: false, prefixes: nil)
          attr_reader option

          default = values&.first if default.nil? && !allow_nil
          prefixes ||= name.deconstantize.underscore.delete_prefix('active_webhook').split('/')
          prefixes.shift if prefixes.first.blank?

          @options ||= {}
          @options[option] = {
            values: values,
            default: default,
            allow_proc: allow_proc,
            prefixes: prefixes
          }

          const_set option.to_s.pluralize.upcase, values

          define_method "#{option}=" do |value|
            unless (allow_proc && value.respond_to?(:call)) ||
                   (allow_nil && value.nil?) ||
                   values.empty? ||
                   values.include?(value)
              raise Configuration::InvalidOptionError.new (prefixes + [option]).compact.join('.'), value,
                                                          values
            end

            instance_variable_set "@#{option}", value
          end
        end

        def define_component(component_name)
          @components ||= []
          @components << component_name
          require "#{name.deconstantize.to_s.underscore}/#{component_name}/configuration"
          attr_reader component_name
        end
      end
    end

    include Base

    define_component :models
    ADAPTERS = %i[delivery formatting queueing verification].freeze
    ADAPTERS.each { |component| define_component component }

    define_option :origin
    define_option :enabled, values: [true, false]

    def origin=(value)
      if (@origin = value).nil?
        ActiveWebhook.remove_class_variable(:@@origin) if ActiveWebhook.class_variable_defined?(:@@origin)
      else
        ActiveWebhook.class_variable_set(:@@origin, value)
      end
    end

    def after_configure
      # reset logger,
      # ActiveWebhook.class_variable_set(:@logger, nil)
      # cause all adapter files specified to be loaded
      ADAPTERS.each { |type| ActiveWebhook.send "#{type}_adapter" }

      # (re)set relationships for all models
      models.error_log.belongs_to :subscription, class_name: models.subscription.name, foreign_key: :subscription_id
      models.topic.has_many :subscriptions, class_name: models.subscription.name, foreign_key: :topic_id
      models.subscription.belongs_to :topic, class_name: models.topic.name, foreign_key: :topic_id
      models.subscription.has_many :error_logs, class_name: models.error_log.name, foreign_key: :subscription_id

      self
    end
  end
end
