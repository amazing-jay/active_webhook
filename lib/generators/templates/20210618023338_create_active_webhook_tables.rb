# frozen_string_literal: true

class CreateActiveWebhookTables < ActiveRecord::Migration[4.2]
  def change
    create_table :active_webhook_subscriptions do |t|
      t.references :topic, class: :active_webhook_topic
      t.text :callback_url
      t.text :shared_secret
      t.datetime :disabled_at
      t.string :disabled_reason

      t.timestamps
    end

    create_table :active_webhook_topics do |t|
      t.string :key
      t.string :version
      t.datetime :disabled_at
      t.string :disabled_reason

      t.timestamps
    end

    create_table :active_webhook_error_logs do |t|
      t.references :subscription, class: :active_webhook_subscription
      t.string :job_id

      t.timestamps
    end
  end
end
