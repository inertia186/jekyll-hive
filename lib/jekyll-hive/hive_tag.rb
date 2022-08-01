# frozen_string_literal: true

require 'cgi'
require 'hive'
require 'open-uri'
require 'fileutils'

Net::OpenTimeout = Class.new(RuntimeError) unless Net.const_defined?(:OpenTimeout)
Net::ReadTimeout = Class.new(RuntimeError) unless Net.const_defined?(:ReadTimeout)

module Jekyll
  module Hive
    
    # Use the tag as follows in your Jekyll pages, posts and collections:
    # 
    #     {% hive author/permlink %}
    class HiveTag < Liquid::Tag
      def render(context)
        @encoding = context.registers[:site].config['encoding'] || 'utf-8'
        @settings = context.registers[:site].config['hive']
        
        if (tag_contents = determine_arguments(@markup.strip))
          hive_slug = tag_contents[0]
          attempts = 0
          content = nil
          rebuild = ENV.fetch("JEKYLL_HIVE_REBUILD", 'false') == 'true'
          
          loop do
            warn "Attempts for #{hive_slug}: #{attempts}" if attempts > 0
            
            if attempts > 4
              warn "Gave up on: #{hive_slug}"
              delete_content_cache(hive_slug)
              break
            end
            
            begin
              attempts = attempts + 1
              
              if !!rebuild && !!content_cache(hive_slug)
                if content_age(hive_slug) > 9000
                  # TODO quickly check if the cache should be cleared
                  
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
            rescue => e
              warn "Retrying: #{hive_slug} (#{e})"
              @api = nil
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
        
        unless !!@content_cache
          @content_cache ||= {}

          Dir.mkdir cache_dir_path unless Dir.exists? cache_dir_path
          
          Dir.glob("#{cache_dir_path}/*") do |filename|
            next if File.directory? filename
            
            @content_cache[filename.split('/').last] = File.open(filename).read
          end
        end
        
        if !!value && value != ''
          @content_cache[key] ||= value
          
          File.open(cached_file(hive_slug), 'wb') do |cache_file|
            cache_file.write(value)
          end
        end
        
        if @content_cache[key] == ''
          delete_content_cache(hive_slug)
          
          nil
        else
          @content_cache[key]
        end
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
      
      def api
        url = ENV.fetch('NODE_URL', 'https://api.hive.blog,https://api.openhive.network').split(',').sample
        
        @api ||= ::Hive::CondenserApi.new(url: url)
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

        # TODO find a better way to get the `created` timestamp, this is really
        # no faster than just parsing the content.
        api.get_content(author, permlink) do |content|
          created = Time.parse(content.created + 'Z')
          
          cached_created > created
        end
      end
      
      def hive_tag(hive_slug)
        author, permlink = parse_slug(hive_slug)
        
        api.get_content(author, permlink) do |content|
          body = content.body
          metadata = JSON[content.json_metadata] rescue nil || {}
          canonical_url = metadata.fetch('canonical_url', "https://hive.blog/@#{author}/#{permlink}")
          
          # This will normalize image hoster proxy URLs that the author copied
          # from another post.
          
          body = body.gsub(/https:\/\/steemitimages.com\/[0-9]+x0\/https:\/\//, 'https://')
          body = body.gsub(/https:\/\/images.hive.blog\/[0-9]+x0\/https:\/\//, 'https://')
          body = body.gsub(/https:\/\/images.esteem.app\/[0-9]+x0\/https:\/\//, 'https://')
          
          scrape = URI::open(canonical_url).read

          if scrape.include? 'rel="canonical"'
            canonical_url = scrape.split('rel="canonical"')[1].split('"')[1]
          end

          "<div id=\"content-#{author}-#{permlink}\">" + body + <<~DONE
          </div>
          <script crossorigin='anonymous' integrity='sha256-4+XzXVhsDmqanXGHaHvgh1gMQKX40OUvDEBTu8JcmNs=' src='https://code.jquery.com/jquery-3.5.1.slim.min.js'></script>
          <script src='https://unpkg.com/steem-content-renderer'></script>
          <!-- <script src="https://cdn.jsdelivr.net/npm/hive-content-renderer/dist/hive-content-renderer.min.js"></script> -->
          <script>
            $(document).ready(function() {
              try {
                const renderer = new SteemContentRenderer.DefaultRenderer({
                // const renderer = new HiveContentRenderer({
                  baseUrl: "https://hive.blog/",
                  breaks: true,
                  skipSanitization: false,
                  allowInsecureScriptTags: false,
                  addNofollowToLinks: true,
                  doNotShowImages: false,
                  ipfsPrefix: "",
                  assetsWidth: 640,
                  assetsHeight: 480,
                  imageProxyFn: (url) => url,
                  usertagUrlFn: (account) => "/@#{author}",
                  hashtagUrlFn: (hashtag) => "/#{permlink}",
                  isLinkSafeFn: (url) => true,
                });
                
                const inputElem = $('#content-#{author}-#{permlink}').html();
                const outputElem = $('#content-#{author}-#{permlink}');
                const output = renderer.render(inputElem);
                
                outputElem.html(output);
              } catch(e) {
                console.log(e);
              }
            });
          </script>
          <style>
            #content-#{author}-#{permlink} {
              padding: 0 3rem;
              color: #444444;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              font-size: 16px;
              line-height: 1.8;
              text-shadow: 0 1px 0 #ffffff;
              padding: 0.5rem;
            }
            #content-#{author}-#{permlink} code {
              background: white;
            }
            #content-#{author}-#{permlink} a {
              border-bottom: 1px solid #444444; color: #444444; text-decoration: none;
            }
            #content-#{author}-#{permlink} a:hover {
              border-bottom: 0;
            }
            #content-#{author}-#{permlink} h1 {
              font-size: 2.2em;
            }
            #content-#{author}-#{permlink} h2, h3, h4, h5 {
              margin-bottom: 0;
            }
            #content-#{author}-#{permlink} header small {
              color: #999;
              font-size: 50%;
            }
            #content-#{author}-#{permlink} img {
              max-width: 100%;
            }
          </style>
          \n<hr />
          <p>
            See: <a href="#{canonical_url}">#{content.title}</a>
            by
            <a href="https://hive.blog/@#{author}">@#{author}</a>
          </p>
          DONE
        end
      end
    end
  end
end

Liquid::Template.register_tag('hive', Jekyll::Hive::HiveTag)
