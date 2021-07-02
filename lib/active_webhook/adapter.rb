# frozen_string_literal: true

module ActiveWebhook
  class Adapter
    extend Memoist
    # TODO: memoize everything in all adapters

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

        # # byebug
        # # puts ['start', self, @attributes].join(', ')
        # @attributes ||= ancestors.each_with_object([]) do |ancestor, attrs|
        #   # break attrs if ancestor == ActiveWebhook::Adapter

        #   if ancestor != self
        #     if ancestor.respond_to?(:attributes)
        #       break attrs += ancestor.attributes
        #     end
        #   end
        #   attrs

        #   # puts ['searching', ancestor, attrs].join(', ')

        #   # byebug
        #   # break attrs if ancestor == ActiveWebhook::Adapter
        #   # break attrs if ancestor != self && ancestor.respond_to?(:attributes))
        #   # byebug
        #   # attrs
        # end
        # puts ['finished', self, @attributes].join(' ,')
        # # byebug
        # # @attributes ||= []
        # @attributes
      end

      def attribute(*attrs)
        # Module.new.tap do |m| # Using anonymous modules so that super can be used to extend accessor methods
        # include m

        attrs = attrs.map(&:to_sym)
        (attrs - attributes).each do |attr_name|
          attributes << attr_name.to_sym
          # m.attr_accessor attr_name
          attr_accessor attr_name
          # end
        end
      end

      # def inherited(subclass)
      #   byebug
      #   # super
      #   subclass.instance_variable_set(:@attributes, ancestors.each_with_object([]) do |ancestor, attrs|
      #                                                  unless ancestor == self || !ancestor.respond_to?(:attributes)
      #                                                    break attrs += ancestor.attributes
      #                                                  end

      #                                                  attrs
      #                                                end)
      #   # byebug
      #   # x = 1
      # end

      def call(*args, **kwargs, &block)
        new(*args, **kwargs).call(&block)
      end

      def component_name
        raise NotImplementedError, ".component_name must be implemented."
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
      self.context = kwargs #.symbolize_keys! #with_indifferent_access
    end

    def call
      raise NotImplementedError, "#call must be implemented."
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
