# frozen_string_literal: true

require 'cgi'
require 'steem'

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
          
          hive_tag(hive_slug)
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
      def determine_arguments(input)
        return unless input =~ /@?[^\/]+\/[^\/]+/i
        
        [input]
      end
      
      def hive_tag(hive_slug)
        hive_slug = hive_slug.split('@').last
        hive_slug = hive_slug.split('/')
        author = hive_slug[0]
        permlink = hive_slug[1..-1].join('/')
        permlink = permlink.split('?').first
        permlink = permlink.split('#').first
        api = ::Steem::CondenserApi.new(url: ENV.fetch('NODE_URL', 'https://api.openhive.network'))
        
        api.get_content(author, permlink) do |content|
          body = content.body
          metadata = JSON[content.json_metadata] rescue nil || {}
          canonical_url = metadata.fetch('canonical_url', "https://hive.blog/@#{author}/#{permlink}")
          
          # This will normalize image hoster proxy URLs that the author copied
          # from another post.
          
          body = body.gsub(/https:\/\/steemitimages.com\/[0-9]+x0\/https:\/\//, 'https://')
          body = body.gsub(/https:\/\/images.hive.blog\/[0-9]+x0\/https:\/\//, 'https://')
          
          # Although it works on hive.blog and many other markdown interpretors,
          # kramdown doesn't like this, so we have to fix it:
          # 
          # <div>
          #   This *won't* work.
          # </div>
          #
          # See: https://stackoverflow.blog/2008/06/25/three-markdown-gotcha/
          
          body = body.gsub(/<([^\/].+)>(.+)<\/\1>/m) do
            match = Regexp.last_match
            html = Kramdown::Document.new(match[2]).to_html
            
            "<#{match[1]}>#{html.gsub("\n", "<br />")}</#{match[1]}>"
          end
          
          body + <<~DONE
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
