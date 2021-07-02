# frozen_string_literal: true

RSpec.describe ActiveWebhook::Delivery::BaseAdapter, config: :defaults do
  describe ".call", with_time: :frozen do
    let(:hook) { ActiveWebhook::Hook.new }
    let(:subscription) { create :subscription }
    let(:adapter) { }

    context "with max_errors_per_hour" do
      before do
        ActiveWebhook.configure do |config|
          config.delivery.max_errors_per_hour = 1
        end
        allow_any_instance_of(described_class).to receive(:deliver!) do |i|
          raise StandardError, "xxx"
        end
      end

      it do
        expect{described_class.call(subscription: subscription, hook: hook)}.to raise_error StandardError, "xxx"
        expect(subscription.reload.disabled?).to eq false
        expect(subscription.error_logs.count).to eq 1

        expect{described_class.call(subscription: subscription, hook: hook)}.to raise_error StandardError, "xxx"
        expect(subscription.reload.disabled?).to eq false
        expect(subscription.error_logs.count).to eq 2

        expect{described_class.call(subscription: subscription, hook: hook)}.not_to raise_error
        expect(subscription.reload.disabled?).to eq true
        expect(subscription.error_logs.count).to eq 2

        subscription.enable!
        expect(subscription.reload.disabled?).to eq false
        expect(subscription.error_logs.count).to eq 0

        expect{described_class.call(subscription: subscription, hook: hook)}.to raise_error StandardError, "xxx"
        expect{described_class.call(subscription: subscription, hook: hook)}.to raise_error StandardError, "xxx"
        expect(subscription.reload.disabled?).to eq false
        expect(subscription.error_logs.count).to eq 2

        expect{
          described_class.call(subscription: subscription, hook: hook, max_errors_per_hour: 2)
        }.to raise_error StandardError, "xxx"
        expect(subscription.reload.disabled?).to eq false
        expect(subscription.error_logs.count).to eq 3

        expect{
          described_class.call(subscription: subscription, hook: hook, max_errors_per_hour: 2)
        }.not_to raise_error
        expect(subscription.reload.disabled?).to eq true
        expect(subscription.error_logs.count).to eq 3
      end
    end
  end
end
