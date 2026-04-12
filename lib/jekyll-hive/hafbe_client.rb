# frozen_string_literal: true

require 'dimapa'
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
        comment_operations = operations.select do |entry|
          entry.dig('op', 'type') == 'comment_operation'
        end

        raise 'Unexpected HAFBE response shape' if comment_operations.empty?

        base_entry = comment_operations.find do |entry|
          body = entry.dig('op', 'value', 'body').to_s
          !diff_match_patch?(body)
        end || comment_operations.first

        post = deep_copy(base_entry.dig('op', 'value'))
        raise 'Unexpected HAFBE response shape' unless post.is_a?(Hash)

        post['created'] ||= base_entry['timestamp'] if base_entry['timestamp']

        subsequent_entries = comment_operations.drop_while { |entry| entry != base_entry }.drop(1)
        subsequent_entries.each do |entry|
          apply_revision!(post, entry)
        end

        post
      end

      def apply_revision!(post, entry)
        revision = entry.dig('op', 'value')
        return unless revision.is_a?(Hash)

        if revision.key?('title') && !revision['title'].to_s.empty?
          post['title'] = revision['title']
        end

        if revision.key?('json_metadata') && !revision['json_metadata'].to_s.empty?
          post['json_metadata'] = revision['json_metadata']
        end

        body = revision['body'].to_s
        return if body.empty?

        post['body'] = if diff_match_patch?(body)
                         apply_diff_match_patch(post['body'].to_s, body)
                       else
                         body
                       end
      end

      def diff_match_patch?(body)
        body.start_with?('@@') || body.start_with?('@@ ')
      end

      def apply_diff_match_patch(original_body, patch_text)
        dmp = DiMaPa.new
        patches = dmp.patch_from_text(patch_text)
        updated_body, = dmp.patch_apply(patches, original_body)
        updated_body
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end

      def escape(segment)
        URI.encode_www_form_component(segment.to_s)
      end
    end
  end
end
