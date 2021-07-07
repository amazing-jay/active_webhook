# Active Webhook

[![Build Status](https://travis-ci.com/amazing-jay/active_webhook.svg?branch=master)](https://travis-ci.com/amazing-jay/active_webhook)
[![Test Coverage](https://codecov.io/gh/amazing-jay/active_webhook/graph/badge.svg)](https://codecov.io/gh/amazing-jay/active_webhook)

Simple, efficient, extensible webhooks for Ruby.

Features include:

- Rate Limits
- Cryptographic Signatures
- Asynchronous Delivery
- Versioning

## What does an Active Webhook look like?

By default, ActiveWebhook delivers HTTP POST requests with the following:

#### HEADERS

```json
{
  "Content-Type": "application/json",
  "User-Agent": "Active Webhook v0.1.0",
  "Origin": "http://my-custom-domain.com",
  "X-Hmac-SHA256": "iDCMPCGuPaq3F9hhEYdcBmIBU6aVOEZakS8GmJbLzoU=",
  "X-Time": "2021-06-29 06:20:26 UTC",
  "X-Topic": "abcdef",
  "X-Topic-Version": "3.73",
  "X-Webhook-Type": "event",
  "X-Webhook-Id": "6f35615cb30a6c51a29bedeb"
  },
}
```

#### BODY
```json
{
  "data": {}
}
```

_See the [Configuration](https://github.com/amazing-jay/active_webhook#configuration) and [Customization](https://github.com/amazing-jay/active_webhook#customization) sections to learn more._

## Requirements

Active Webhook supports (_but does not require_) Rails 5+ and various queueing
and delivery technologies (e.g. Sidekiq, Delayed Job, Active Job, Net HTTP, Faraday, etc.).

## Download and Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_webhook'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_webhook

Source code can be downloaded on GitHub
[github.com/amazing-jay/active_webhook/tree/master](https://github.com/amazing-jay/active_webhook/tree/master)

## Setup

### Generate required files

    $ rails g active_webhook:install
    $ rails db:migrate

### Create webhook topics

A **Webhook Topic** is a persisted data object (ActiveRecord) that describes a specific type of event which triggers a webhook, and is uniquely identified by a key (e.g. “user/created”) and version (e.g. “1.1”).


    $ rails g migration create_active_webhook_topics

Then edit the migration file:

```ruby
# in db/migrate/20210618023338_create_active_webhook_topics.rb

# This is just an example, you can define any topic keys that you want to define
class CreateActiveWebhookTopics < ActiveRecord::Migration[4.2]
  def change
    # If you do omit a value for`version` when creating a Topic, ActiveWebhook will autoincrement one for you.
    ActiveWebhook::Topic.create(key: "user/created")
  end
end
```

And migrate:

    $ rails db:migrate
    $ rails db:test:prepare

### Create webhook subscriptions

A **Webhook Subscription** is a persisted data object (ActiveRecord) that describes a webhook topic which you want to receive notifications about, and a callback url.

When a Topic is triggered, Active Webhook will attempt delivery of each Subscription registered for that topic. You can create multiple subscriptions for the same topic.

To register a Subscription, simply execute
`ActiveWebhook::Subscription.create(callback_url: url, topic: topic)`, where:

- `callback_url` is a required string that must be a valid URL
- `topic` is a previously defined Topic

e.g.

```ruby
ActiveWebhook::Subscription.create(
  callback_url: 'http://myappdomain.com/webhooks',
  topic: ActiveWebhook::Topic.find_by_key('user/created')
)
# or
ActiveWebhook::Subscription.create(
  callback_url: 'http://myappdomain.com/webhooks',
  topic: ActiveWebhook::Topic.where(key: 'user/deleted', version: '1.1').first
)
```

_See the [Self Subscription](https://github.com/amazing-jay/active_webhook#example-2--enable-users-to-self-subscribe-for-the-topics-that-they-care-about) section to learn how to setup self-registration for your users._

## Usage

### Triggering webhooks

To trigger the delivery of a topic, simply execute `ActiveWebhook.trigger(key: key)`, where `key` is a required string that identifies a Topic for delivery (must
  match the `key` of at least one previously defined Topic).

### Options

The `trigger` method accepts any number of optional kwarg arguments, some of which have special meaning:

- `version` is a string that scopes delivery of Topics by version (if omitted, all topics with matching key will be triggered during the queueing phase).
- `format_first` is a boolean that causes the hook to be built syncronously (if omitted, the default configuration value is used during the queueing phase).
- `data` is a hash that will become the payload body during the build phase (if omitted, a default payload body will be built).
- `type` is a string that will become the value of the 'X-Webhook-Type' header during the build phase.
- `max_errors_per_hour` is a integer that causes subscriptions to be disabled (if omitted, the default configuration value is used during the delivery phase).

All other keyword arguments supplied will be passed forward to each adapter for later use by any customizations that you implement.

_See the [Configuration](https://github.com/amazing-jay/active_webhook#configuration) Section for more information about default configuration options._

Examples::

```ruby
ActiveWebhook.trigger(key: 'user/created')
ActiveWebhook.trigger(key: 'user/deleted', version: '1.1')
ActiveWebhook.trigger(key: 'user/deleted', data: { id: 1 }, my_option: 'random_value')
```

### ActiveRecord callbacks

The following convenience methods are available when working with ActiveRecord objects:

```ruby
# app/models/application_record.rb

# note: trigger_webhooks is defined in ActiveWebhook::Callbacks, which is mixed into ActiveRecord::Base
class ApplicationRecord < ActiveRecord::Base
  # enable after_commit callbacks for created and deleted topic
  trigger_webhooks except: :updated

  # conditionally trigger the updated topic
  after_commit on: :updated do
    trigger_webhook :updated if state_changed?
  end
end
```

```ruby
# app/models/invoice.rb

class Invoice < ApplicationRecord
  # override the default behavior to trigger an additional topic
  def trigger_updated_webhook
    trigger_webhook(:sent) if previous_changes.key?("sent_at")

    super
  end
```

#### Special payload for webhooks triggered by ActiveRecord callbacks

When using ActiveRecord callbacks, the default payload will be set to `resource.as_json`, and the default type option will be set to "resource".

By way of example:

```ruby
# app/models/application_record.rb

class User < ApplicationRecord
  def send_reminder
    # this:
    trigger_webhook(:reminded)
    # is more-or-less equivalent to an optimized version of this:
    # ActiveWebhook.trigger(key: 'user/reminded', data: self.as_json, type: "resource")
  end
end
```

#### Defining topics for activeRecord callbacks

Don't forget to create topics for each of the models that you want to enable ActiveRecord callbacks for.

```ruby
# in db/migrate/20210618023338_create_active_webhook_topics.rb

# This is just an example, you can define any topics that you want to define
class CreateActiveWebhookTopics < ActiveRecord::Migration[4.2]
  def change
    # define default callback topics for all models + a special topic
    ActiveRecord::Base.connection.tables.each do |table|
      %W(created updated deleted special).each do |event|
        ActiveWebhook::Topic.create(key: "#{table.singularize}/#{event}", version: "1.0")
      end
    end

    # define a second version of the user/created topic so we can conditionally deliver a different payload to subscribers
    ActiveWebhook::Topic.create(key: "user/created", version: "1.1")

    # define a custom topic
    ActiveWebhook::Topic.create(key: "invoice/sent")
  end
end
```

## Configuration

_NOTE: See [config/active_webhook.rb](https://github.com/amazing-jay/active_webhook/blob/master/lib/generators/templates/active_webhook_config.rb) for details about all available configuration options._

### Adapters

Active Webhook ships with queueing and delivery adapters for:

- Sidekiq
- BackgroundJob
- ActiveJob
- Net::HTTP
- Faraday

To activate any adapter, simply uncomment the relevant declaration in the generated
Active Webhook configuration file, and then install relevant dependencies (if any).

For example, to activate the [sidekiq](https://github.com/mperham/sidekiq)
queueing adapter:

```ruby
# in config/active_webhook.rb

require "active_webhook"

ActiveWebhook.configure do |config|
  config.adapters.queueing = :sidekiq
end
```

```ruby
# in Gemfile

gem "sidekiq"
```

_NOTE: Active Webhook does not register official dependencies for any of the
gems required by the various adapters so as to not bloat your application with
unused/incompatible gems. This means that you will have to manually install and
configure all gems required by the adapters that you use (via command line or
Bundler)._

## Customization

This section illustrates the extensibility of Active Webhook.

The following examples will help you:

- Scope Subscription delivery by tenant (aka `Company`)
- Enable users to self-subscribe for the topics that they care about
- Conditionally customize the payload structure

### Example #1 :: Scope Subscription delivery by tenant (aka Company)

    $ rails g migration add_company_to_active_webhook_subscriptions

```ruby
# db/migrate/20210618023339_add_company_to_active_webhook_subscriptions.rb

class AddCompanyToActiveWebhookSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_reference :active_webhook_subscriptions, :company
  end
end
```

```ruby
# app/models/application_record.rb

# note: trigger_webhooks is defined in ActiveWebhook::Callbacks, which is mixed into ActiveRecord::Base
class ApplicationRecord < ActiveRecord::Base
  def trigger_webhook(key, version: nil, **context)
    context[:company_id] ||= company_id if respond_to?(:company_id)
    context[:company_id] ||= company&.id if respond_to?(:company)
    super
  end
end
```

```ruby
# app/lib/webhook/queueing_adapter.rb

require "active_webhook/queueing/sidekiq_adapter"

module Webhook
  class QueueingAdapter < ActiveWebhook::Queueing::SidekiqAdapter
    # qualify subscriptions by tenant
    def subscriptions_scope
      scope = super
      scope = scope.where(company_id: company_id) if company_id.present?
      scope
    end

    def company_id
      context[:company_id]
    end
  end
end
```

```ruby
# app/models/active_webhook/subscription.rb

# reopen class and add relation
class ActiveWebhook::Subscription
  belongs_to :company
end
```


### Example #2 :: Enable users to self-subscribe for the topics that they care about

    $ rails g migration add_user_to_active_webhook_subscriptions

```ruby
# db/migrate/20210618023339_add_user_to_active_webhook_subscriptions.rb

class AddUserToActiveWebhookSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_reference :active_webhook_subscriptions, :user
  end
end
```

```ruby
# app/models/company.rb

# note: trigger_webhooks is defined in ActiveWebhook::Callbacks, which is mixed into ActiveRecord::Base
class User < ApplicationRecord
  has_many :webhook_subscriptions
end
```

```ruby
# app/models/webhook_subscription.rb

class WebhookSubscription < ApplicationRecord
  include ActiveWebhook::Models::SubscriptionAdditions
  belongs_to :user
end
```

```ruby
# in config/active_webhook.rb

require "active_webhook"

ActiveWebhook.configure do |config|
  # use our custom Subscription class rather than the default
  config.models.subscription = WebhookSubscription
end
```

```ruby
# in app/controllers/webhook_subscriptions
module Webhooks
  class SubscriptionsController < ApplicationController
    def create
      @user = User.find params.permit(:user_id)
      @user.webhook_subscriptions.build_webhook_subscription params.require(:webhook_subscription).permit(
        :callback_url,
        :topic_id
      )
      @user.save!
    end
  end
end
```

### Example #3 :: Conditionally customize the payload

```ruby
# in config/active_webhook.rb
ActiveWebhook.configure do |c|
  c.adapters.formatting = MySpecialFormatter
end
```

```ruby
# in lib/webhooks/my_special_formatter.rb
# note: This is just an example. Custom formatters do not need to inherit from ActiveWebhook::Formatting::SimpleFormatting.
class Webhooks::MySpecialFormatter < ActiveWebhook::Formatting::JsonAdapter
  def self.call(subscription, **context)
    payload = super
    payload["type"] = "special" if subscription.topic_key.ends_with? "/special"
    payload.delete("something other key")
    payload
  end
end
```

...or, alternatively

```ruby
# in config/active_webhook.rb
ActiveWebhook.configure do |c|
  c.adapters.formatting = Class.new(ActiveWebhook::Formatting::JsonAdapter) do
    def self.call(subscription, **context)
      payload = super
      payload["type"] = "special" if subscription.topic_key.ends_with? "/special"
      payload.delete("something other key")
      payload
    end
  end
end
```

For more information, see the files located at:

- [lib/active_webhook/queueing](https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/queueing)
- [lib/active_webhook/delivery](https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/delivery)
- [lib/active_webhook/verification](https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/verification)
- [lib/active_webhook/formatting](https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/formatting)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/amazing-jay/active_webhook.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## ROADMAP

* Add rubocop to travis build (or publish task)
* Figure out flakey. specs
* Add XML format
* Dummy app; create a local subscription class
* Upgrade callbacks_spec to use a real model and table defined in a migration
* Upgrade logger spec to expect stubbed logger to receive and call original (and drop the rest)
* Disable subscriptions when jobs stop
* Consolidate formatting adapters and configuration options into a single builder
* Add buffered delivery
* Memoize everything in all adapters
- Add hook when error limit disabled subscribtion?
