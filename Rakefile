require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'
require 'jekyll'
require 'jekyll-hive'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

namespace :clean do
  desc 'Deletes spec/fixtures/vcr_cassettes/*.yml so they can be rebuilt fresh.'
  task :vcr do |t|
    exec 'rm -v spec/fixtures/vcr_cassettes/*.yml'
  end
end

desc 'Build a new version of the jekyll-hive gem.'
task :build do
  exec 'gem build jekyll-hive.gemspec'
end

desc "Publish jekyll-hive-#{Jekyll::Hive::VERSION}.gem."
task :push do
  exec "gem push jekyll-hive-#{Jekyll::Hive::VERSION}.gem"
end

# We're not going to yank on a regular basis, but this is how it's done if you
# really want a task for that for some reason.

# desc 'Yank jekyll-hive-#{Jekyll::Hive::VERSION}.gem.'
# task :yank do
#   exec "gem yank jekyll-hive -v #{Jekyll::Hive::VERSION}"
# end
