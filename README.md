# Jekyll::Steem

Liquid tag for displaying Steem content in Jekyll sites: `{% steem %}`.

[![Build Status](https://travis-ci.org/inertia186/jekyll-steem.svg?branch=master)](https://travis-ci.org/inertia186/jekyll-steem)

## Installation

Add this line to your application's Gemfile:

```bash
gem 'jekyll-steem'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install jekyll-steem
```

Then add the following to your site's `_config.yml`:

```yml
plugins:
  - jekyll-steem
```

💡 If you are using a Jekyll version less than 3.5.0, use the `gems` key instead of `plugins`.

## Usage

Use the tag as follows in your Jekyll pages, posts and collections:

```liquid
{% steem author/permlink %}
```

This will place the associated content on the page.

## Contributing

1. Fork it ( https://github.com/inertia186/jekyll-steem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

---

<center>
  <img src="https://i.imgur.com/9iXdqM9.png" />
</center>

## Get in touch!

If you're using Jekyll::Steem, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm [@inertia](https://steemit.com/@inertia) on STEEM.
  
## License

I don't believe in intellectual "property".  If you do, consider Jekyll::Steem as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
