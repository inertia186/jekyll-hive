# frozen_string_literal: true

require 'simplecov'

SimpleCov.start
SimpleCov.merge_timeout 3600

TEST_DIR = __dir__
TMP_DIR  = File.expand_path('../tmp', TEST_DIR)

require 'webmock'
require 'vcr'
require 'cgi'
require 'jekyll'
require File.expand_path('../lib/jekyll-hive.rb', TEST_DIR)

Jekyll.logger.log_level = :error

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  
  def tmp_dir(*files)
    File.join(TMP_DIR, *files)
  end
  
  def source_dir(*files)
    tmp_dir('source', *files)
  end
  
  def dest_dir(*files)
    tmp_dir('dest', *files)
  end
  
  def doc_with_content(_content, opts = {})
    my_site = site(opts)
    Jekyll::Document.new(source_dir('_test/doc.md'), { :site => my_site, :collection => collection(my_site) })
  end
  
  def collection(site, label = 'test')
    Jekyll::Collection.new(site, label)
  end
  
  def site(opts = {})
    conf = Jekyll::Utils.deep_merge_hashes(Jekyll::Configuration::DEFAULTS, opts.merge({
      'source'      => source_dir,
      'destination' => dest_dir,
    }))
    Jekyll::Site.new(conf)
  end
  
  def fixture(name)
    path = File.expand_path 'fixtures/#{name}.json', __dir__
    File.open(path).read
  end
end
