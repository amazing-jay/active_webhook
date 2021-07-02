# frozen_string_literal: true

RSpec.describe ActiveWebhook::Models::SubscriptionAdditions, type: :model do
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      def self.name
        'TestModel'
      end
    end.tap do |klass|
      klass.include(described_class)
      ActiveWebhook.configure { |config| config.models.subscription = klass }
    end
  end

  context ".included" do
    let(:topic) { create :topic }
    let(:attributes) { { disabled_at: nil, topic: topic, callback_url: 'http://example.com' } }
    let(:instance) { test_class.new(**attributes) }

    it { expect(instance.disabled?).to be_falsey }
    it { expect(instance.enabled?).to be_truthy }
    it { expect{instance.enable!}.not_to raise_error }
    it { expect{instance.disable!}.not_to raise_error }

    it do
      instance.enable
      instance.save
      instance.reload
      expect(instance.enabled?).to be_truthy
    end

    it do
      instance.disable
      instance.save
      instance.reload
      expect(instance.disabled?).to be_truthy
    end

    context "when prior instances exist" do
      let!(:disabled_instance) { test_class.create(**attributes.merge(disabled_at: Time.current)) }
      let!(:prior_instance) { test_class.create(**attributes) }
      let!(:instance) { test_class.create(**attributes) }

      it { expect(instance.reload.topic).to eq(topic) }

      it { expect(test_class.enabled.count).to eq(2) }
    end
  end
end
