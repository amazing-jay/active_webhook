# frozen_string_literal: true

module ActiveWebhook
  Hook = Struct.new :url, :headers, :body do
    def self.from_h(url: '', headers: {}, body: "")
      new url, headers, body
    end
  end
end
