# frozen_string_literal: true

module ActiveWebhook
  module Models
    module ErrorLogAdditions
      extend ActiveSupport::Concern

      included do
        self.table_name = "active_webhook_error_logs"

        validates_presence_of :subscription
      end
    end
  end
end
