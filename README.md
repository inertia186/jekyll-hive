# Jekyll::Hive

Liquid tag for displaying Hive content in Jekyll sites: `{% hive %}`.

[![Build Status](https://travis-ci.org/inertia186/jekyll-hive.svg?branch=master)](https://travis-ci.org/inertia186/jekyll-hive)

## Installation

Add this line to your application's Gemfile:

```bash
gem 'jekyll-hive'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install jekyll-hive
```

Then add the following to your site's `_config.yml`:

```yml
plugins:
  - jekyll-hive
```

💡 If you are using a Jekyll version less than 3.5.0, use the `gems` key instead of `plugins`.

## Usage

Use the tag as follows in your Jekyll pages, posts and collections:

```liquid
{% hive author/permlink %}
```
This will place the associated content on the page.

## Jekyll Build

When building your site with jekyll, you can continue to use the default command:

```bash
jekyll build
```

If you would like to provide an alternate node:

```bash
NODE_URL=https://anyx.io jekyll build
```

## Contributing

1. Fork it ( https://github.com/inertia186/jekyll-hive/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

---

<center>
  <img src="https://i.imgur.com/Yy47F6h.png" />
</center>

## Get in touch!

If you're using Jekyll::Hive, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm [@inertia](https://hive.blog/@inertia) on Hive.
  
## License

I don't believe in intellectual "property".  If you do, consider Jekyll::Hive as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
