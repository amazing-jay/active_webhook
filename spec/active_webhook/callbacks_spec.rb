# frozen_string_literal: true

RSpec.describe ActiveWebhook::Callbacks do

  describe ".trigger", with_time: :frozen do
    let(:created) { create :subscription, topic: create(:topic, key: "custom/created") }
    let(:updated) { create :subscription, topic: create(:topic, key: "custom/updated") }
    let(:deleted) { create :subscription, topic: create(:topic, key: "custom/deleted") }

    let(:last_created_topic) { ActiveWebhook::Topic.last }
    let(:create_subscriptions) do
      created
      updated
      deleted
    end

    let(:test_class) do
      Class.new(ActiveRecord::Base) do
        # HACK: re-use topics table so we don't have to create another
        def self.name
          'Custom'
        end
      end.tap do |klass|
        klass.table_name = 'active_webhook_topics'
        klass.trigger_webhooks
      end
    end

    it do
      create_subscriptions
      requests = subscription_requests(
        created,
        skip: [ updated, deleted ]
      ) do |_subscription, _url, params, _requests|
        params[:body] = { data: { id: last_created_topic.id + 1, type: 'Custom'} }
        params[:headers]["X-Webhook-Type"] = "resource"
      end
      expect_requests(requests) { test_class.create }
    end

    it do
      custom_instance = test_class.create
      create_subscriptions

      requests = subscription_requests(
        updated,
        skip: [ created, deleted ]
      ) do |_subscription, _url, params, _requests|
        params[:body] = { data: { id: custom_instance.id, type: 'Custom'} }
        params[:headers]["X-Webhook-Type"] = "resource"
      end
      expect_requests(requests) { custom_instance.update(updated_at: 10.seconds.from_now) }
    end

    it "should skip empty updates" do
      custom_instance = test_class.create
      create_subscriptions

      requests = subscription_requests(
        skip: [ created, updated, deleted ]
      ) do |_subscription, _url, params, _requests|
        params[:body] = { data: { id: custom_instance.id, type: 'Custom'} }
        params[:headers]["X-Webhook-Type"] = "resource"
      end
      expect_requests(requests) { custom_instance.touch }
    end

    it do
      custom_instance = test_class.create
      create_subscriptions

      requests = subscription_requests(
        deleted,
        skip: [ created, updated ]
      ) do |_subscription, _url, params, _requests|
        params[:body] = { data: { id: custom_instance.id, type: 'Custom'} }
        params[:headers]["X-Webhook-Type"] = "resource"
      end
      expect_requests(requests) { custom_instance.destroy }
    end
  end
end
