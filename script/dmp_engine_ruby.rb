#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dimapa'
require 'json'

payload = JSON.parse($stdin.read)
dmp = DiMaPa.new

results = payload.fetch('vectors', []).map do |vector|
  entry = {
    'name' => vector['name'],
    'parsed' => false,
    'applied' => false,
    'final_text' => nil,
    'error' => nil
  }

  begin
    patches = dmp.patch_from_text(vector['patch_text'].to_s)
    entry['parsed'] = true
    final_text, applied_flags = dmp.patch_apply(patches, vector['base_text'].to_s)
    entry['applied'] = Array(applied_flags).all?
    entry['final_text'] = final_text
    entry['applied_flags'] = Array(applied_flags)
  rescue StandardError => e
    entry['error'] = e.message
  end

  entry
end

puts JSON.pretty_generate({
  'available' => true,
  'engine' => 'ruby_dimapa',
  'results' => results
})
