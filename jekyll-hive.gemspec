# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-hive/version'

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-hive'
  spec.version       = Jekyll::Hive::VERSION
  spec.authors       = ['Anthony Martin']
  spec.email         = ['jekyll-hive@martin-studio.com']
  spec.summary       = 'Liquid tag for displaying Hive content in Jekyll sites.'
  spec.homepage      = 'https://github.com/inertia186/jekyll-hive'
  spec.license       = 'CC0-1.0'

  spec.required_ruby_version = '>= 2.3.0'

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  spec.executables   = spec.files.grep(%r!^bin/!) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r!^(test|spec|features)/!)
  spec.require_paths = ['lib']


  spec.add_dependency 'dimapa', '~> 0.1'
  spec.add_dependency 'jekyll', '>= 3.5', '< 5.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '>= 3.0', '< 4.0'
  spec.add_development_dependency 'rubocop-jekyll', '>= 0.4', '< 1.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yard', '~> 0.9'
end
