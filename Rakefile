#!/usr/bin/env rake

def initialize_rake_environment
  return unless require_relative "config/environment"
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

task default: :spec

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-performance"
  task.requires << "rubocop-rspec"
end
