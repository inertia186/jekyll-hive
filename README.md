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

## Front-end dependencies

As of the v2 branch, the `{% hive %}` tag emits structured embed markup and expects rendering dependencies to be loaded once by your site layout instead of being injected for every post.

At minimum, load your renderer and any supporting scripts/styles in a shared include such as `_includes/head.html` or your main layout. For example:

```html
<script src='https://unpkg.com/steem-content-renderer'></script>
<script src='/assets/javascript/universal-bridge-against-phishing.js'></script>
<script src='/assets/javascript/lazysizes.min.js' async></script>
```

Then run a single page-level bootstrap pass against the generated embed targets, such as elements marked with `data-hive-render-target="true"`.

## Legacy cache warning

If `jekyll-hive` detects cache entries created by the older inline-script / inline-style output format, it will warn once per build and recommend deleting `.jekyll-hive-cache` so the cache can be regenerated in the v2 format.

## Jekyll Build

When building your site with jekyll, you can continue to use the default command:

```bash
jekyll build
```

If you would like to provide an alternate node:

```bash
NODE_URL=https://anyx.io jekyll build
```

## Jekyll Clean

To completely rebuild your site without cache:

```bash
rm -rf .jekyll-hive-cache && jekyll clean && jekyll build
```

## Troubleshooting

#### I saw several messages like:

```
Retrying: stoodkev/how-to-use-hivejs-or-other-modules-referencing-core-node-js-modules-on-react-native (Failed to open TCP connection to api.hive.blog:443 (getaddrinfo: nodename nor servname provided, or not known))
Retrying: stoodkev/how-to-use-hivejs-or-other-modules-referencing-core-node-js-modules-on-react-native (Failed to open TCP connection to api.openhive.network:443 (getaddrinfo: nodename nor servname provided, or not known))
.
.
.
Gave up on: stoodkev/how-to-use-hivejs-or-other-modules-referencing-core-node-js-modules-on-react-native
```

Check your internet connection or provide an alternate node:

```
NODE_URL=https://anyx.io jekyll build
```

#### The post has changed on the blockchain, but `jekyll-hive` won't update to the latest post revision.

The cached copy is out of date.  Try deleting the related post from the cache or remove the entire cache:

```
rm -rf .jekyll-hive-cache
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
