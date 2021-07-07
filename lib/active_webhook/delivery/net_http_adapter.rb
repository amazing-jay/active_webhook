# frozen_string_literal: true

require 'uri'
require 'net/http'

module ActiveWebhook
  module Delivery
    class NetHTTPAdapter < BaseAdapter
      def status_code
        response.code.to_i
      end

      protected

      def deliver!
        uri = URI.parse(url.strip)

        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = body
        headers.each { |k, v| request[k] = v }

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme.casecmp('https').zero?
        http.request(request)
      end
    end
  end
end
