# frozen_string_literal: true

module ActiveWebhook
  class ErrorLog < ActiveRecord::Base
    include ActiveWebhook::Models::ErrorLogAdditions
  end
end
