# frozen_string_literal: true

require "dotenv/load"

ENV["RACK_ENV"] ||= ENV["RAILS_ENV"] ||= "development"

require "bundler/setup"

if RUBY_ENGINE == "jruby"
  # Workaround for issue in I18n/JRuby combo.
  # See https://github.com/jruby/jruby/issues/6547 and
  # https://github.com/ruby-i18n/i18n/issues/555
  require "i18n/backend"
  require "i18n/backend/simple"
end

environments = [ENV["RAILS_ENV"].to_sym]
environments << :development if environments.last == :test

Bundler.require(*environments)

SimpleCov.start if ENV['RAILS_ENV'].to_s == "test"
SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV["CI"] == "true"

require "active_webhook"

db_config = File.read([__dir__.delete_suffix('/config'), "spec/dummy/config/database.yml"].join("/"))
db_config = ERB.new(db_config).result
db_config = YAML.safe_load(db_config, [], [], true)
DB_CONFIG = db_config[ENV["RAILS_ENV"]]
ActiveRecord::Base.establish_connection(DB_CONFIG)

FactoryBot.find_definitions if %w(test development).include? ENV["RAILS_ENV"]
