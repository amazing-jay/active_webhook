## inspired by

`https://benediktdeicke.com/2017/09/sending-webhooks-with-rails/`

## look at importing server from https://github.com/nsweeting/activehook

## bootstrapped with:

`bundle gem active_webhook --test=rspec --mit`

## bootstrapped dummy rails app with

`rails new dummy --skip-spring --skip-listen --skip-bootsnap --skip-action-text --skip-active-storage --skip-action-cable --skip-action-mailer --skip-action-mailbox --skip-test --skip-system-test --skip-active-job --skip-active-record --skip-javascript`

[then dicarded and used fully dummy]

[SEE](https://lokalise.com/blog/create-a-ruby-gem-basics/)
[SEE](https://lokalise.com/blog/how-to-create-a-ruby-gem-testing-suite/)

rails d model active_webhook/subscription

rails d model active_webhook/topic

rails g model active_webhook/subscription \
 user_id:integer \
 state:tinyint \
 topic_key:string \
 topic_version:string \
 updated_at:datetime \
 disabled_reason:string \
 format:string \
 callback_url:text \
 company_id:integer \
 query:text

rails g model active_webhook/topic \
 key:string \
 version:string \
 state:tinyint \
 query:string \


-------------------------------------------------------------------------------------
# everything below this line is deferred until needed

1. consolidate formatting/*_adapter.rb into hook/builder.rb
   - change content_type & encoded_data methods use ActiveWebhook.configuration.content_type
   - add ActiveWebhook.configuration.builder
   - delete Hook (in favor of basic hash) ?

1. add `config.queueing.delay` trigger(in: nil) => [1.second]
   - do not add to Topic or Subscription models (because they aren't loaded before check for performance reasons)
   - evaluate to config.nil? ? method.option : config.value
   - configure each queuing adapter to pass delay to underlying implementation

1. add `config.buffering.adapter` => [:disabled, :enabled, Buffering::BaseAdapter]
   - introduce shim into queueing/base_adapter#call that passes to active_webbhook/buffer/*adapter and back
   - make sure that all queuing adapters delay after buffer is flushed
   - add buffer/disabled_adapter and buffer/enabled_adapter
   - implement as follows:
     - if enabled, require `request_store`
     - monkey_patch transaction block (or observe callbacks)
     - add `buffer.t_level` and `buffer.entries`
     - store t_level with buffer entry args
     - on rollback, `buffer.entries.delete` where `entry.t_level` >= `buffer.t_level`; then `buffer.t_level -= 1`
     - on commit, `buffer.entries.t.level -= 1` where `entry.t_level` >= `buffer.t_level`; then `buffer.t_level -= 1`
     - if rails, `ActionController.include ActiveWebhook::Buferable` that wraps each action with `begin; ActiveWebhook.buffer.start; ensure; ActiveWebhook.buffer.flush; end
       - note: Def controller might require different implementation from transactions; need to research transaction callbacks and commits during transaction
       - https://github.com/steveklabnik/request_store
       - https://www.justinweiss.com/articles/better-globals-with-a-tiny-activesupport-module/

1. add `ActiveWebhook.cancel(...same args as trigger)`
   - clears matching `buffer.entries` via `buffer.cancel(**kwargs)`
   - relies on `config.buffer.eq?(a, b)`

1. add `config.buffering.remove_duplicates` and trigger(remove_duplicates: nil, **) [true, false]
   - do not add to Topic or Subscription models (because they aren't loaded before check for performance reasons)
   - evaluate to config.nil? ? method.option : config.value
   - raise runtime error if true and bufferring_adapter is disabled
   - relies on `config.buffer.eq?(a, b)`

1. add `config.delivery.retry_count` and trigger(retry_count: nil, **) [true, false]
   - do not add to Topic or Subscription models (because they aren't loaded before check for performance reasons)
   - evaluate to config.nil? ? method.option : config.value
   - solve how to specify retry count with exponential backoff for each queuing adapter
   - match option name to active_job

1. add `config.delivery.time_limit` and trigger(time_limit: nil, **) [true, false]
   - do not add to Topic or Subscription models (because they aren't loaded before check for performance reasons)
   - evaluate to config.nil? ? method.option : config.value
   - solve how to specify time limit for each queuing adapter
   - match option name to active_job

1. add jid to context in syncronous queuing adapter (if possible)
   - solve how to generate an auto increment Id across servers (maybe hash or hex a server id and counter; could store server in db and load on start)
   - https://www.google.com/search?q=rails+set+global+variable+per+request&client=safari&hl=en-us&ei=xF3NYKDaKYX_-wSAu5KIAw&oq=rails+set+global+variable+per+request



Scratchpad
---
# in spec/spec_helper.rb

# Restablish connection (severed from app load)
ActiveRecord::Base.establish_connection(DB_CONFIG)

# log sql (as level debug)
ActiveRecord::Base.logger = Rails.logger


----
# in Rakefile

# require "bundler/gem_tasks"
# require "rspec/core/rake_task"
#   Bundler::GemHelper.install_tasks
# rescue LoadError
#   puts "although not required, bundler is recommended for running the tests"
# end
# require "rake"

# RSpec::Core::RakeTask.new(:spec) do |spec|
#   spec.pattern = 'spec/**/*_spec.rb'
# end

# namespace :db do
#   desc "Create the database"
#   task :create do
#     initialize_rake_environment
#     if ActiveRecord::Base.connection.respond_to? :create_database
#       ActiveRecord::Base.connection.create_database(DB_CONFIG["database"])
#     else
#       ActiveRecord::Base.connection.send :connect
#     end
#     puts "Database created."
#   end

#   desc "Migrate the database"
#   task :migrate do
#     initialize_rake_environment
#     ActiveRecord::Base.connection.migration_context.migrate
#     Rake::Task["db:schema"].invoke
#     puts "Database migrated."
#   end

#   desc "Drop the database"
#   task :drop do
#     initialize_rake_environment
#     ActiveRecord::Base.connection.close
#     if ActiveRecord::Base.connection.respond_to? :drop_database
#       ActiveRecord::Base.connection.drop_database(DB_CONFIG["database"])
#     else
#       f = [__dir__, "db", "#{ENV['RACK_ENV']}.sqlite3"].join("/")
#       File.delete(f) if File.exist?(f)
#     end
#     puts "Database deleted."
#   end

#   desc "Reset the database"
#   task :reset => %i[drop create migrate]

#   desc "Create a db/schema.rb file that is portable against any DB supported by AR"
#   task :schema do
#     initialize_rake_environment
#     require "active_record/schema_dumper"
#     filename = "db/schema.rb"
#     File.open(filename, "w:utf-8") do |file|
#       ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
#     end
#   end
# end

# namespace :g do
#   desc "Generate migration"
#   task :migration do
#     initialize_rake_environment
#     name = ARGV[1] || raise("Specify name: rake g:migration your_migration")
#     timestamp = Time.now.strftime("%Y%m%d%H%M%S")
#     path = File.expand_path("../db/migrate/#{timestamp}_#{name}.rb", __FILE__)
#     migration_class = name.split("_").map(&:capitalize).join

#     File.open(path, "w") do |file|
#       file.write <<~FILE
#         class #{migration_class} < ActiveRecord::Migration
#           def self.up
#           end
#           def self.down
#           end
#         end
#       FILE
#     end

#     puts "Migration #{path} created"
#     abort # needed stop other tasks
#   end
# end



