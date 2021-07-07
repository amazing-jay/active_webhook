# frozen_string_literal: true

module ActiveWebhook
  class Adapter
    extend Memoist

    class << self
      def attributes
        @attributes ||= if self == ActiveWebhook::Adapter
                          []
                        else
                          ancestors.each_with_object([]) do |ancestor, attrs|
                            break attrs += ancestor.attributes if ancestor != self && ancestor.respond_to?(:attributes)

                            attrs
                          end
                        end
      end

      def attribute(*attrs)
        attrs = attrs.map(&:to_sym)
        (attrs - attributes).each do |attr_name|
          attributes << attr_name.to_sym
          attr_accessor attr_name
        end
      end

      def call(*args, **kwargs, &block)
        new(*args, **kwargs).call(&block)
      end

      def component_name
        raise NotImplementedError, '.component_name must be implemented.'
      end

      def configuration
        ActiveWebhook.configuration
      end

      def component_configuration
        configuration.send(component_name)
      end
    end

    attribute :context

    def initialize(**kwargs)
      self.class.attributes.each do |attr_name|
        send("#{attr_name}=", kwargs[attr_name]) unless attr_name == :context
      end
      self.context = kwargs
    end

    def call
      raise NotImplementedError, '#call must be implemented.'
    end

    def attributes
      self.class.attributes.each_with_object({}) do |attr_name, h|
        h[attr_name] = send(attr_name)
      end
    end

    def configuration
      self.class.configuration
    end

    def component_configuration
      self.class.component_configuration
    end
  end
end
