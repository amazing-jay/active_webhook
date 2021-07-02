# frozen_string_literal: true

require "active_webhook/formatting/json_adapter"

RSpec.describe ActiveWebhook::Formatting::JSONAdapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.formatting.adapter = :json }
  end

  describe ".trigger", with_time: :frozen do
    let(:key) { "abcdef" }
    let(:topic) { create :topic, key: key }
    let(:versioned_topic) { create :topic, key: key }
    let(:subscription) { create :subscription, topic: topic }
    let(:other_subscription) { create :subscription, topic: topic }
    let(:versioned_subscription) { create :subscription, topic: versioned_topic }
    let(:ignored_subscription) { create :subscription }

    it do
      expect_subscription_requests(
        subscription,
        other_subscription,
        versioned_subscription,
        skip: ignored_subscription
      ) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
    end

    context "with formatting.custom_header_prefix" do
      before do
        ActiveWebhook.configure { |config| config.formatting.custom_header_prefix = "xxx" }
      end

      it do
        requests = subscription_requests(
          subscription,
          other_subscription,
          versioned_subscription,
          skip: ignored_subscription
        ) do |_subscription, _url, params, _requests|
          params[:headers].transform_keys! do |key|
            if key.starts_with?("X-")
              parts = key.split("-")
              parts.insert(1, "Xxx")
              parts.join("-")
            else
              key
            end
          end
        end
        expect_requests(requests) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
      end
    end

    context "with formatting.user_agent" do
      before do
        ActiveWebhook.configure { |config| config.formatting.user_agent = "xxx" }
      end

      it do
        requests = subscription_requests(
          subscription,
          other_subscription,
          versioned_subscription,
          skip: ignored_subscription
        ) do |_subscription, _url, params, _requests|
          params[:headers]["User-Agent"] = "xxx"
        end
        expect_requests(requests) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
      end
    end
  end
end
