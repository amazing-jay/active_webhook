# frozen_string_literal: true

module ActiveWebhook
  class Subscription < ActiveRecord::Base
    include ActiveWebhook::Models::SubscriptionAdditions
  end
end
