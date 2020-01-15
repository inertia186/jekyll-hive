# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-steem/version'

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-steem'
  spec.version       = Jekyll::Steem::VERSION
  spec.authors       = ['Anthony Martin']
  spec.email         = ['jekyll-steem@martin-studio.com']
  spec.summary       = 'Liquid tag for displaying Steem content in Jekyll sites.'
  spec.homepage      = 'https://github.com/inertia186/jekyll-steem'
  spec.license       = 'CC0-1.0'

  spec.required_ruby_version = '>= 2.3.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r!^bin/!) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r!^(test|spec|features)/!)
  spec.require_paths = ['lib']

  spec.add_dependency 'steem-ruby', '~> 0.9'
  
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'jekyll'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop-jekyll', '~> 0.4'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
