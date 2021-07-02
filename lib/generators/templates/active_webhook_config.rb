# frozen_string_literal: true

require "active_webhook"

ApplicationRecord.include ActiveWebhook::Callbacks

ActiveWebhook.configure do |c|
  # Inject your Rails Application name into all custom headers for outgoing webhooks
  # c.custom_header_prefix = Rails.application.class.to_s.split("::").first

  # Specify a custom origin name to use for x-Domain header in outgoing webhooks
  # c.origin = 'http://'

  # Format the payload BEFORE queuing for delivery.
  # Helpful when queuing delay is problematic, but comes with the trade of poor performance profile.
  # c.formatting.format_first = true                  # << one of: [true, false]

  # Base class for Active Webhook Models (Subscription & Topic)
  # c.model_base_class = ApplicationRecord

  # --------------------------------------------------------------------------------------------------------------

  # !!! IMPORTANT !!!
  #
  # YOU WILL NEED INSTALL AND CONFIGURE ALL DEPENDENCIES OF THE ADAPTERS THAT YOU USE.
  #
  # Active Webhook does not register official dependencies for any of the
  # gems required by the various adapters (so as to not bloat your application with
  # unused/incompatible gems). This means that you will have to manually install and
  # configure all gems required by the adapters that you use (via command line or
  # Bundler).
  #
  # For example, to activate the [sidekiq](https://github.com/mperham/sidekiq)
  # queuing adapter:
  #
  # ```ruby
  # # in config/active_webhook.rb
  #
  # require "active_webhook"
  #
  # ActiveWebhook.configure do |config|
  #   config.queue_adapter = :sidekiq
  # end
  # ```
  #
  # ```ruby
  # # in Gemfile
  #
  # gem "sidekiq"
  # ```
  # --------------------------------------------------------------------------------------------------------------

  # Queue asynchronous delivery with active_job.
  # c.adapters.queueing = :active_job                # << one of: [:sidekiq, :active_job, :syncronous]

  # Deliver the payload with Faraday.
  # c.adapters.delivery = :faraday                   # << one of: [:net_http, :faraday]

  # Sign the payload with HMAC_SHA256.
  # c.adapters.verification = :hmac_sha256           # << one of: [:hmac_sha256]

  # Serialize the payload as json.
  # c.adapters.formatting = :json                    # << one of: [:json]

  # --------------------------------------------------------------------------------------------------------------

  # Note: For extensibility, all adaptors also accept an object (or Proc) that implements `call(**kwargs)`.
  #
  # Queue asynchronous delivery with custom adapter.
  # c.adapters.queueing = Class.new do
  #   def self.call(subscription_id:, **context) do
  #   # ... cause `ActiveWebhook.fulfill_delivery(subscription_id:, payload:, **context)` to be called at a later date
  # end
  #
  # - or -
  #
  # c.adapters.queueing = ->(subscription_id:, **context) do
  #   # ... cause `ActiveWebhook.fulfill_delivery(subscription_id:, payload:, **context)` to be called at a later date
  # end
  #
  # For more information, see the files located at:
  #
  # - (lib/active_webhook/queueing)[https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/queueing]
  # - (lib/active_webhook/delivery)[https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/delivery]
  # - (lib/active_webhook/verification)[https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/verification]
  # - (lib/active_webhook/formatting)[https://github.com/amazing-jay/active_webhook/tree/master/lib/active_webhook/formatting]
end
