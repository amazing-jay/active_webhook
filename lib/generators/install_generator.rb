# frozen_string_literal: true

require "rails/generators"

module ActiveWebhook
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates all the files needed to use Active Webhook"

      def copy_config
        template "active_webhook_config.rb", Rails.root.join('config','active_webhook.rb')
      end

      def run_other_generators
        invoke "active_webhook:migrations"
      end
    end
  end
end
