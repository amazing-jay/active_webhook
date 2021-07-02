# frozen_string_literal: true

module SuiteHelpers
  # USAGE
  # expect_subscription_requests(
  #   subscription,
  #   other_subscription,
  #   versioned_subscription
  # ) { expect(described_class.trigger(key: key)).to be_truthy }
  def expect_subscription_requests(*subscriptions, skip: [], &block)
    requests = subscription_requests(*subscriptions, skip: skip)
    expect_requests(requests, &block)
  end

  # USAGE
  # subscription_requests(
  #   subscription,
  #   other_subscription,
  #   versioned_subscription
  # ) { expect(described_class.trigger(key: key)).to be_truthy }
  def subscription_requests(*subscriptions, skip: [])
    skip = Array.wrap(skip)
    headers = {
      "Accept" => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Content-Type" => "application/json",
      "User-Agent" => ActiveWebhook.configuration.formatting.user_agent,
      "X-Webhook-Type" => "event"
    }
    (subscriptions + skip).reverse.each_with_object({}) do |subscription, requests|
      url = subscription.callback_url
      requests[url] = params = {
        body: { data: {} },
        headers: headers.merge({
                                 "X-Time" => Time.current.to_s,
                                 "X-Topic" => subscription.topic.key,
                                 "X-Topic-Version" => subscription.topic.version.to_s
                               }),
        skip: skip.include?(subscription)
      }

      yield(subscription, url, params, requests) if block_given?
    end
  end

  # USAGE
  # expect_hooks_around(
  #   [
  #     subscription,
  #     other_subscription,
  #     versioned_subscription
  #   ].each_with_object({}) do |sub, requests|
  #     requests[sub.callback_url] = {
  #       body: "{}",
  #       headers: {
  #         "Accept" => "*/*",
  #         "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
  #         "Content-Type" => "application/json",
  #         "User-Agent" => "Ruby",
  #         "X-Time" => Time.current.to_s,
  #         "X-Topic" => sub.topic.key,
  #         "X-Topic-Version" => sub.topic.version.to_s
  #         "X-Webhook-Type" => "event",
  #       }
  #     }
  #   end
  # ) { expect(described_class.trigger(key: key)).to be_truthy }
  def expect_requests(requests)
    Rails.logger.debug "Stubbing requests: #{requests.ai}" if Rails.logger.level == 0
    requests.each do |url, body: nil, headers: {}, **rest|
      stub_request(:post, url).
        with(body: (body.is_a?(String) ? body : body.to_json), headers: headers).
        and_return(status: 200, body: "", headers: {})
    end

    yield

    requests.each do |url, skip: false, **params|
      if skip
        expect(WebMock).not_to have_requested(:post, url).with(**params)
      else
        expect(WebMock).to have_requested(:post, url).with(**params).once
      end
    end
  end
end
