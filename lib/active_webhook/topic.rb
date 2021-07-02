# frozen_string_literal: true

module ActiveWebhook
  class Topic < ActiveRecord::Base
    include ActiveWebhook::Models::TopicAdditions
  end
end
