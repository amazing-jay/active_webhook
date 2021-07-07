# frozen_string_literal: true

module ActiveWebhook
  module Verification
    class BaseAdapter < Adapter
      attribute :secret, :data

      def call
        return {} unless secret.present?

        {
          strategy => signature
        }
      end

      protected

      def self.component_name
        'verification'
      end

      def signature
        raise NotImplementedError, '#signature must be implemented.'
      end

      def strategy
        self.class.name.delete_suffix('Adapter')
      end
    end
  end
end
