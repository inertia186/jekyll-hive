# frozen_string_literal: true

require 'cgi'
require 'steem'

Net::OpenTimeout = Class.new(RuntimeError) unless Net.const_defined?(:OpenTimeout)
Net::ReadTimeout = Class.new(RuntimeError) unless Net.const_defined?(:ReadTimeout)

module Jekyll
  module Steem
    
    # Use the tag as follows in your Jekyll pages, posts and collections:
    # 
    #     {% steem author/permlink %}
    class SteemTag < Liquid::Tag
      def render(context)
        @encoding = context.registers[:site].config['encoding'] || 'utf-8'
        @settings = context.registers[:site].config['steem']
        
        if (tag_contents = determine_arguments(@markup.strip))
          steem_slug = tag_contents[0]
          
          steem_tag(steem_slug)
        else
          raise ArgumentError, <<~ERROR
            Syntax error in tag 'steem' while parsing the following markup:
             #{@markup}
             Valid syntax:
              {% steem author/permlink %}

          ERROR
        end
      end
    private
      def determine_arguments(input)
        return unless input =~ /@?[^\/]+\/[^\/]+/i
        
        [input]
      end
      
      def steem_tag(steem_slug)
        steem_slug = steem_slug.split('@').last
        steem_slug = steem_slug.split('/')
        author = steem_slug[0]
        permlink = steem_slug[1..-1].join('/')
        permlink = permlink.split('?').first
        permlink = permlink.split('#').first
        api = ::Steem::CondenserApi.new
        
        api.get_content(author, permlink) do |content|
          body = content.body
          metadata = JSON[content.json_metadata] rescue nil || {}
          canonical_url = metadata.fetch('canonical_url', "https://steemit.com/@#{author}/#{permlink}")
          
          # This will normalize image hoster proxy URLs that the author copied
          # from another post.
          
          body = body.gsub(/https:\/\/steemitimages.com\/[0-9]+x0\/https:\/\//, 'https://')
          
          # Although it works on steemit.com and many other markdown interpretors,
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
            <a href="https://steemit.com/@#{author}">@#{author}</a>
          </p>
          DONE
        end
      end
    end
  end
end

Liquid::Template.register_tag('steem', Jekyll::Steem::SteemTag)
