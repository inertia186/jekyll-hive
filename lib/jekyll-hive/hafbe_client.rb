# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Jekyll
  module Hive
    class HafbeClient
      DEFAULT_API_URL = 'https://api.hive.blog/hafbe-api'.freeze

      attr_reader :api_url

      def initialize(api_url: ENV.fetch('HAFBE_API_URL', DEFAULT_API_URL))
        @api_url = api_url
      end

      def fetch_post(author, permlink)
        response = get("/accounts/#{escape(author)}/operations/comments/#{escape(permlink)}")
        normalize_post(response)
      rescue StandardError => e
        raise "HAFBE request failed for @#{author}/#{permlink}: #{e.message}"
      end

      private

      def get(path, params = {})
        base = api_url.sub(%r{/$}, '')
        uri = URI(base + path)
        uri.query = URI.encode_www_form(params) unless params.empty?
        response = Net::HTTP.get_response(uri)

        unless response.is_a?(Net::HTTPSuccess)
          raise "HTTP #{response.code}"
        end

        JSON.parse(response.body)
      end

      def normalize_post(payload)
        operations = Array(payload['operations_result'])
        first_comment = operations.find do |entry|
          entry.dig('op', 'type') == 'comment_operation'
        end

        post = first_comment&.dig('op', 'value')
        post = post.merge('created' => first_comment['timestamp']) if post && first_comment && !post.key?('created')
        return post if post.is_a?(Hash)

        raise 'Unexpected HAFBE response shape'
      end

      def escape(segment)
        URI.encode_www_form_component(segment.to_s)
      end
    end
  end
end
