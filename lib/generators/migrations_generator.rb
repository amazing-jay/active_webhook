# frozen_string_literal: true

require "rails/generators"

module ActiveWebhook
  module Generators
    class MigrationsGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      desc "Creates the migrations needed to use Active Webhook"

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "20210618023338_create_active_webhook_tables.rb",
                           Rails.root.join('db','migrate','create_active_webhook_tables.rb')
      end
    end
  end
end
