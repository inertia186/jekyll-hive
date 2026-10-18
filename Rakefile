require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

# We're not going to yank on a regular basis, but this is how it's done if you
# really want a task for that for some reason.

# desc 'Yank jekyll-hive-#{Jekyll::Hive::VERSION}.gem.'
# task :yank do
#   exec "gem yank jekyll-hive -v #{Jekyll::Hive::VERSION}"
# end
