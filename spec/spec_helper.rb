# frozen_string_literal: true

ENV["RACK_ENV"] ||= ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

Rails.logger = Logger.new($stdout)

require "active_support/testing/time_helpers"

require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on a
    # real object. This is generally recommended, and will default to `true` in
    # RSpec 4.
    mocks.verify_partial_doubles = true
  end

  Dir["#{__dir__}/support/**/*.rb"].sort.each do |file_name|
    config.include file_name.split("/spec/support/").last.delete_suffix(".rb").camelize.constantize
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include ActiveSupport::Testing::TimeHelpers, with_time: true

  config.around(:example, with_time: :frozen) do |example|
    freeze_time do
      example.run
    end
  end

  config.around(:example, log_level: true) do |example|
    level = Rails.logger.level
    Rails.logger.level = example.metadata[:log_level]
    example.run
    ActiveRecord::Base.logger.level = level
  end

  config.before(:each, :config => :defaults) do
    ActiveWebhook.instance_variable_set(:@configuration, nil)
    ActiveWebhook.configure do |config| end
  end
end

# load the dummy application
require_relative "dummy/config/environment"
require "rspec/rails"

# set log level from ENV (default :warn)
LOG_LEVELS = ["debug", "info", "warn", "error", "fatal", "unknown"].freeze
log_level = ENV.fetch("LOG_LEVEL", "warn")
Rails.logger.level = LOG_LEVELS.index(log_level) || log_level.to_i

ENV["RAILS_ROOT"] ||= "#{File.dirname(__FILE__)}/dummy"
