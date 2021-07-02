# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_webhook/version"

Gem::Specification.new do |spec|
  spec.name          = "active_webhook"
  spec.version       = ActiveWebhook::VERSION
  spec.authors       = ["Jay Crouch"]
  spec.email         = ["i.jaycrouch@gmail.com"]

  spec.summary       = "Simple, efficient, and extensible webhooks for Ruby."
  spec.description   = "Simple, efficient, and extensible webhooks for Ruby, including: Rate Limits, Cryptographic " \
                       "Signatures, Asynchronous Delivery, Buffered Delivery, Versioning."
  spec.homepage      = "https://github.com/amazing-jay/active_webhook"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/amazing-jay/active_webhook"
    spec.metadata["changelog_uri"] = "https://github.com/amazing-jay/active_webhook/master/tree/CHANGELOG.md."
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) }
  end

  spec.bindir                      = "exe"
  spec.executables                 = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths               = ["lib"]
  spec.required_ruby_version       = ">= 2.5"

  spec.add_dependency "activerecord", ">= 5.0.0"
  spec.add_dependency "memoist"

  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "dotenv", "~> 2.5"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "faraday"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "listen"
  spec.add_development_dependency "pry-byebug"

  # must come before those below
  if ENV['TEST_RAILS_VERSION'].nil?
    spec.add_development_dependency 'rails', '~> 6.1.3.2'
  else
    spec.add_development_dependency 'rails', ENV['TEST_RAILS_VERSION'].to_s
  end

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop", "~> 0.60"
  spec.add_development_dependency "rubocop-performance", "~> 1.5"
  spec.add_development_dependency "rubocop-rspec", "~> 1.37"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"
  spec.add_development_dependency "sidekiq"
  spec.add_development_dependency "rspec-sidekiq"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "delayed_job_active_record"
end
