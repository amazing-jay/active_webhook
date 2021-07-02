# frozen_string_literal: true

require "active_webhook/verification/hmac_sha256_adapter"

RSpec.describe ActiveWebhook::Verification::HMACSHA256Adapter, config: :defaults do
  before do
    ActiveWebhook.configure { |config| config.verification.adapter = :hmac_sha256 }
  end

  describe ".trigger", with_time: :frozen do
    let(:key) { "abcdef" }
    let(:topic) { create :topic, key: key }
    let(:versioned_topic) { create :topic, key: key }
    let(:subscription) { create :subscription, topic: topic }
    let(:other_subscription) { create :subscription, topic: topic }
    let(:versioned_subscription) { create :subscription, topic: versioned_topic }
    let(:ignored_subscription) { create :subscription }
    let(:subscriptions) do
      [
        subscription,
        other_subscription,
        versioned_subscription,
        ignored_subscription
      ]
    end

    it do
      requests = subscription_requests(
        subscription,
        other_subscription,
        versioned_subscription,
        skip: ignored_subscription
      ) do |subscription, _url, params, _requests|
        params[:headers].merge!(
          "X-Hmac-SHA256" =>
            Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", subscription.shared_secret, params[:body].to_json))
        )
      end
      expect_requests(requests) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
    end
  end
end
