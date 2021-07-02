# frozen_string_literal: true

RSpec.describe ActiveWebhook, config: :defaults do
  it "has a version number" do
    expect(ActiveWebhook::VERSION).not_to be nil
  end

  it "has an identifier" do
    expect(ActiveWebhook::IDENTIFIER).to eq "Active Webhook v#{ActiveWebhook::VERSION}"
  end

  describe ".configure" do
    [
      {
        option: :origin
      },
      {
        option: :enabled,
        default: true,
        value: false,
        valid_values: ["true", "false"]
      },
      {
        targets: :delivery,
        option: :adapter,
        default: :net_http,
        value: :faraday,
        valid_values: [":net_http", ":faraday"]
      },
      {
        targets: :formatting,
        option: :user_agent,
        default: ActiveWebhook::IDENTIFIER
      },
      {
        targets: :formatting,
        option: :adapter,
        default: :json,
        value: :url_encoded,
        valid_values: [":json", ":url_encoded"]
      },
      {
        targets: :formatting,
        option: :custom_header_prefix
      },
      {
        targets: :queueing,
        option: :adapter,
        default: :syncronous,
        value: :sidekiq,
        valid_values: [":syncronous", ":sidekiq", ":delayed_job", ":active_job"]
      },
      {
        targets: :queueing,
        option: :format_first,
        default: false,
        value: true,
        valid_values: ["true", "false"]
      },
      {
        targets: :verification,
        option: :adapter,
        default: :unsigned,
        value: :hmac_sha256,
        valid_values: [":unsigned", ":hmac_sha256"]
      }
    ].each do |option:, default: nil, value: nil, valid_values: [], targets: []|
      targets = Array.wrap(targets)

      unless valid_values.empty?
        context "with valid value" do
          subject do
            described_class.configure do |config|
              target = config
              targets.each { |msg| target = target.send(msg) }
              target.send("#{option}=", value)
            end
          end

          it do
            target = described_class.configuration
            targets.each { |msg| target = target.send(msg) }
            expect { subject }.to change(target, option).from(default).to(value)
          end
        end
      end

      context "with :xxx" do
        subject do
          described_class.configure do |config|
            target = config
            targets.each { |msg| target = target.send(msg) }
            target.send("#{option}=", :xxx)
          end
        end

        it do
          if valid_values.empty?
            target = described_class.configuration
            targets.each { |msg| target = target.send(msg) }
            expect { subject }.to change(target, option).from(default).to(:xxx)
          else
            expect { subject }.to raise_error(
              ActiveWebhook::Configuration::InvalidOptionError,
              "Invalid option for #{(targets + [option]).join('.')}: xxx. Must be one of [#{valid_values.join(', ')}]."
            )
          end
        end
      end
    end
  end

  describe ".trigger", with_time: :frozen do
    let(:key) { "abcdef" }
    let(:topic) { create :topic, key: key }
    let(:versioned_topic) { create :topic, key: key }
    let(:subscription) { create :subscription, topic: topic }
    let(:other_subscription) { create :subscription, topic: topic }
    let(:versioned_subscription) { create :subscription, topic: versioned_topic }
    let(:ignored_subscription) { create :subscription }

    it "should succeed with default configuration" do
      expect_subscription_requests(
        subscription,
        other_subscription,
        versioned_subscription,
        skip: ignored_subscription
      ) { expect(described_class.trigger(key: key)).to be_truthy }
    end

    context "with version" do
      it do
        expect_subscription_requests(
          subscription,
          other_subscription,
          skip: [
            ignored_subscription,
            versioned_subscription
          ]
        ) { expect(described_class.trigger(key: key, version: topic.version)).to be_truthy }
      end
    end

    context "with disabled" do
      before do
        ActiveWebhook.configure { |config| config.enabled = false }
      end

      it do
        subscription
        expect(described_class.trigger(key: key, version: topic.version)).to be_truthy
      end
    end

    context "with origin" do
      before do
        ActiveWebhook.configure { |config| config.origin = "http://my-custom-domain.com" }
      end

      it do
        requests = subscription_requests(
          subscription,
          other_subscription,
          versioned_subscription,
          skip: ignored_subscription
        ) do |_subscription, _url, params, _requests|
          params[:headers]["Origin"] = "http://my-custom-domain.com"
        end
        expect_requests(requests) { expect(ActiveWebhook.trigger(key: key)).to be_truthy }
      end
    end

    context "with log_level == debug", log_level: :debug  do
      before do
        ActiveWebhook.configure do |config|
          # make payload as complex as possible
          config.origin = "http://my-custom-domain.com"
          config.formatting.custom_header_prefix = "XXX"
          config.queueing.adapter = :sidekiq
          config.verification.adapter = :hmac_sha256
        end
        allow_any_instance_of(ActiveWebhook::Delivery::NetHTTPAdapter).to receive(:deliver!) do |i|
          instance_double("Response", :code => 200)
        end
      end

      it "should dump payloads" do
        ActiveWebhook.trigger(key: subscription.topic.key)
        Sidekiq::Worker.drain_all
      end
    end
  end
end
