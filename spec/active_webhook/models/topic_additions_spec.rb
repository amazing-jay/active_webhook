# frozen_string_literal: true

RSpec.describe ActiveWebhook::Models::TopicAdditions, type: :model, config: :default do
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      def self.name
        'TestModel'
      end
    end.tap do |klass|
      klass.include(described_class)
      ActiveWebhook.configure { |config| config.models.topic = klass }
    end
  end

  context ".included" do
    let(:key) { 'some key' }
    let(:attributes) { { disabled_at: nil, key: key } }
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

      it { expect{instance.subscriptions.count}.not_to raise_error }

      it { expect(test_class.enabled.count).to eq(2) }
      it { expect(test_class.with_key(key: key).count).to eq(3) }
      it { expect(test_class.with_key(key: key, version: "1").count).to eq(1) }
      it { expect(test_class.last_with_key(key)).to eq(instance) }

      it { expect(disabled_instance.reload.version).to eq("1") }
      it { expect(prior_instance.reload.version).to eq("2") }
      it { expect(instance.reload.version).to eq("3") }
    end
  end
end
