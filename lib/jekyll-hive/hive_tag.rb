# frozen_string_literal: true

require 'cgi'
require 'json'
require 'open-uri'
require 'fileutils'
require 'set'
require 'time'

Net::OpenTimeout = Class.new(RuntimeError) unless Net.const_defined?(:OpenTimeout)
Net::ReadTimeout = Class.new(RuntimeError) unless Net.const_defined?(:ReadTimeout)

module Jekyll
  module Hive
    # Use the tag as follows in your Jekyll pages, posts and collections:
    #
    #     {% hive author/permlink %}
    class HiveTag < Liquid::Tag
      LEGACY_CACHE_RECOMMENDATION = 'Delete .jekyll-hive-cache and rebuild so jekyll-hive can regenerate cache entries in the v2 format.'
      V2_CACHE_MARKER = 'data-hive-render-target="true"'
      LEGACY_CACHE_MARKERS = [
        'SteemContentRenderer.DefaultRenderer',
        '<script src=\'https://unpkg.com/steem-content-renderer\'',
        '<script src="https://unpkg.com/steem-content-renderer"',
        '<script crossorigin=\'anonymous\' integrity=\'sha256-4+XzXVhsDmqanXGHaHvgh1gMQKX40OUvDEBTu8JcmNs=\' src=\'https://code.jquery.com/jquery-3.5.1.slim.min.js\'',
        '<script src=\'https://code.jquery.com/jquery-3.5.1.slim.min.js\'',
        '<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"'
      ].freeze

      def render(context)
        @site = context.registers[:site]
        @encoding = @site.config['encoding'] || 'utf-8'
        @settings = @site.config['hive'] || {}

        if (tag_contents = determine_arguments(@markup.strip))
          hive_slug = tag_contents[0]
          attempts = 0
          content = nil
          rebuild = ENV.fetch('JEKYLL_HIVE_REBUILD', 'false') == 'true'

          loop do
            warn "Attempts for #{hive_slug}: #{attempts}" if attempts > 0

            if attempts > 4
              warn "Gave up on: #{hive_slug}"
              delete_content_cache(hive_slug)
              break
            end

            begin
              attempts += 1

              if rebuild && content_cache(hive_slug)
                if content_age(hive_slug) > 9000
                  warn "Checking for changes: #{hive_slug}"

                  if content_changed?(hive_slug)
                    warn "Refreshing: #{hive_slug}"
                    delete_content_cache(hive_slug)
                  end
                end

                content_touch(hive_slug)
              end

              content = content_cache(hive_slug) || hive_tag(hive_slug)

              break
            rescue StandardError => e
              warn "Retrying: #{hive_slug} (#{e})"
              sleep 3
            end
          end

          content_cache(hive_slug, content)
        else
          raise ArgumentError, <<~ERROR
            Syntax error in tag 'hive' while parsing the following markup:
             #{@markup}
             Valid syntax:
              {% hive author/permlink %}

          ERROR
        end
      end

      private

      def cache_dir_path
        ENV.fetch('JEKYLL_HIVE_CACHE', '.jekyll-hive-cache')
      end

      def parse_key(hive_slug)
        hive_slug.gsub('/', '-')
      end

      def cached_file(hive_slug)
        key = parse_key(hive_slug)

        cache_dir_path + "/#{key}"
      end

      def content_cache(hive_slug, value = nil)
        key = parse_key(hive_slug)

        unless @content_cache
          @content_cache = {}
          @legacy_cache_warned_keys = Set.new

          FileUtils.mkdir_p(cache_dir_path)

          Dir.glob("#{cache_dir_path}/*") do |filename|
            next if File.directory?(filename)

            cache_key = filename.split('/').last
            cache_value = normalize_utf8(File.binread(filename))
            @content_cache[cache_key] = cache_value
            warn_if_legacy_cache_entry(cache_key, cache_value)
          end
        end

        if value && value != ''
          normalized_value = normalize_utf8(value)
          @content_cache[key] ||= normalized_value

          File.open(cached_file(hive_slug), 'wb') do |cache_file|
            cache_file.write(normalized_value)
          end
        end

        if @content_cache[key] == ''
          delete_content_cache(hive_slug)

          nil
        else
          @content_cache[key]
        end
      end

      def warn_if_legacy_cache_entry(cache_key, cache_value)
        return if @legacy_cache_warned_keys.include?(cache_key)
        return unless legacy_cache_entry?(cache_value)
        return if legacy_cache_warning_emitted?

        @legacy_cache_warned_keys << cache_key
        legacy_cache_warning_emitted!(cache_key)

        warn <<~WARNING.gsub(/\s+/, ' ').strip
          Detected legacy jekyll-hive cache entry #{cache_key.inspect} in #{cache_dir_path}.
          #{LEGACY_CACHE_RECOMMENDATION}
        WARNING
      end

      def legacy_cache_entry?(cache_value)
        return false unless cache_value && cache_value != ''

        normalized_cache_value = normalize_utf8(cache_value)
        return false if normalized_cache_value.include?(V2_CACHE_MARKER)

        LEGACY_CACHE_MARKERS.any? { |marker| normalized_cache_value.include?(marker) }
      end

      def legacy_cache_warning_emitted?
        return false unless @site

        @site.config['jekyll_hive_v2_legacy_cache_warning_emitted'] == true
      end

      def legacy_cache_warning_emitted!(cache_key)
        return unless @site

        @site.config['jekyll_hive_v2_legacy_cache_warning_emitted'] = true
        @site.config['jekyll_hive_v2_legacy_cache_warning_key'] = cache_key
      end

      def normalize_utf8(value)
        return '' if value.nil?

        string = value.is_a?(String) ? value.dup : value.to_s
        string.force_encoding(Encoding::UTF_8)

        return string if string.valid_encoding?

        string.encode(Encoding::UTF_8, Encoding::BINARY, invalid: :replace, undef: :replace, replace: '')
      rescue EncodingError
        value.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
      end

      def content_age(hive_slug)
        age = Time.now - File.mtime(cached_file(hive_slug)) rescue 0
        warn "Age for #{hive_slug}: #{age}"

        age
      end

      def content_touch(hive_slug)
        FileUtils.touch(cached_file(hive_slug))
      end

      def delete_content_cache(hive_slug)
        File.delete(cached_file(hive_slug)) rescue false
      end

      def determine_arguments(input)
        return unless input =~ /@?[^\/]+\/[^\/]+/i

        [input]
      end

      def hafbe_client
        api_url = @settings['hafbe_api_url'] || ENV['HAFBE_API_URL'] || Jekyll::Hive::HafbeClient::DEFAULT_API_URL

        @hafbe_client ||= Jekyll::Hive::HafbeClient.new(api_url: api_url)
      end

      def parse_slug(hive_slug)
        hive_slug = hive_slug.split('@').last
        hive_slug = hive_slug.split('/')
        author = hive_slug[0]
        permlink = hive_slug[1..-1].join('/')
        permlink = permlink.split('?').first
        permlink = permlink.split('#').first

        [author, permlink]
      end

      def content_changed?(hive_slug)
        author, permlink = parse_slug(hive_slug)
        cached_created = File.mtime(cached_file(hive_slug)) rescue Time.now
        content = fetch_content(author, permlink)
        created = Time.parse(content.fetch('created').to_s + 'Z')

        cached_created > created
      end

      def fetch_content(author, permlink)
        hafbe_client.fetch_post(author, permlink)
      end

      def hive_tag(hive_slug)
        author, permlink = parse_slug(hive_slug)
        content = fetch_content(author, permlink)
        body = normalize_utf8(content.fetch('body'))
        metadata = JSON.parse(normalize_utf8(content.fetch('json_metadata', '{}'))) rescue {}
        category = normalize_utf8(content['category']).sub(%r{^/+}, '')
        canonical_url = normalize_utf8(metadata.fetch('canonical_url', ["https://hive.blog", category, "@#{author}", permlink].reject(&:empty?).join('/')))

        body = body.gsub(/https:\/\/steemitimages.com\/[0-9]+x0\/https:\/\//, 'https://')
        body = body.gsub(/https:\/\/images.hive.blog\/[0-9]+x0\/https:\/\//, 'https://')
        body = body.gsub(/https:\/\/images.esteem.app\/[0-9]+x0\/https:\/\//, 'https://')

        scrape = normalize_utf8(URI.open(canonical_url).read)

        if scrape.include? 'rel="canonical"'
          canonical_url = normalize_utf8(scrape.split('rel="canonical"')[1].split('"')[1])
        end

        rendered_canonical_url = CGI.escapeHTML(canonical_url)
        rendered_title = CGI.escapeHTML(normalize_utf8(content.fetch('title', '')))
        rendered_author = CGI.escapeHTML(normalize_utf8(author))
        rendered_permlink = CGI.escapeHTML(normalize_utf8(permlink))
        container_id = "content-#{author}-#{permlink}"
        rendered_container_id = CGI.escapeHTML(normalize_utf8(container_id))

        normalize_utf8(<<~HTML)
          <div class="hive-post-embed" data-hive-author="#{rendered_author}" data-hive-permlink="#{rendered_permlink}">
            <div id="#{rendered_container_id}" class="hive-post-embed__content" data-hive-render-target="true">#{body}</div>
            <footer class="hive-post-embed__source">
              <span class="hive-post-embed__source-label">Source:</span>
              <a href="#{rendered_canonical_url}">#{rendered_title}</a>
              by
              <a href="https://hive.blog/@#{rendered_author}">@#{rendered_author}</a>
            </footer>
          </div>
        HTML
      end
    end
  end
end

Liquid::Template.register_tag('hive', Jekyll::Hive::HiveTag)
