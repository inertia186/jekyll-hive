# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'open3'

RSpec.describe 'synthetic diff-match-patch conformance' do
  let(:vectors_payload) do
    JSON.parse(File.read(File.expand_path('fixtures/diff_match_patch_vectors.json', __dir__)))
  end

  let(:vectors) { vectors_payload.fetch('vectors') }

  let(:frozen_witnesses) do
    JSON.parse(File.read(File.expand_path('fixtures/diff_match_patch_frozen_witnesses.json', __dir__)))
  end

  let(:ruby_helper_path) { File.expand_path('../script/dmp_engine_ruby.rb', __dir__) }
  let(:python_helper_path) { File.expand_path('../script/dmp_engine_python.py', __dir__) }
  let(:repo_python_path) { File.expand_path('../.venv-dmp/bin/python', __dir__) }
  let(:python_command) { File.exist?(repo_python_path) ? repo_python_path : 'python3' }

  def run_helper(*command, input:)
    stdout, stderr, status = Open3.capture3(*command, stdin_data: input)
    {
      'stdout' => stdout,
      'stderr' => stderr,
      'status' => status
    }
  end

  def parse_helper_json(result)
    JSON.parse(result.fetch('stdout'))
  rescue JSON::ParserError
    nil
  end

  def expected_by_name
    @expected_by_name ||= vectors.each_with_object({}) do |vector, memo|
      memo[vector.fetch('name')] = vector.fetch('expect')
    end
  end

  it 'pins Ruby dimapa behavior for the synthetic vectors' do
    input = JSON.generate('vectors' => vectors)
    result = run_helper('bundle', 'exec', 'ruby', ruby_helper_path, input: input)

    expect(result.fetch('status')).to be_success, result.fetch('stderr')

    payload = parse_helper_json(result)
    expect(payload).not_to be_nil
    expect(payload.fetch('engine')).to eq('ruby_dimapa')

    payload.fetch('results').each do |entry|
      expected = expected_by_name.fetch(entry.fetch('name'))
      expect(entry.fetch('parsed')).to eq(expected.fetch('parse'))
      expect(entry.fetch('applied')).to eq(expected.fetch('apply'))
      expect(entry['final_text']).to eq(expected['final_text'])
    end
  end

  it 'agrees with the Python helper when the runtime and library are available' do
    input = JSON.generate('vectors' => vectors)
    result = run_helper(python_command, python_helper_path, input: input)

    if result.fetch('status').exitstatus == 75
      skip('python diff_match_patch helper not available on this machine')
    end

    expect(result.fetch('status')).to be_success, result.fetch('stderr')

    payload = parse_helper_json(result)
    expect(payload).not_to be_nil
    expect(payload.fetch('engine')).to eq('python3_diff_match_patch')

    payload.fetch('results').each do |entry|
      expected = expected_by_name.fetch(entry.fetch('name'))
      expect(entry.fetch('parsed')).to eq(expected.fetch('parse'))
      expect(entry.fetch('applied')).to eq(expected.fetch('apply'))
      expect(entry['final_text']).to eq(expected['final_text'])
    end
  end

  it 'keeps frozen external-engine witnesses structurally sane and aligned where present' do
    engines = frozen_witnesses.fetch('engines')

    expect(engines).to include('python3_diff_match_patch')
    expect(engines).to include('go_diffmatchpatch')

    engines.each_value do |engine|
      expect(engine).to include('results')
      expect(engine.fetch('results')).to be_a(Hash)
    end

    engines.each do |engine_name, engine|
      engine.fetch('results').each do |vector_name, frozen_result|
        expected = expected_by_name.fetch(vector_name)
        expect(frozen_result.fetch('parsed')).to eq(expected.fetch('parse')), "#{engine_name} parsed mismatch for #{vector_name}"
        expect(frozen_result.fetch('applied')).to eq(expected.fetch('apply')), "#{engine_name} applied mismatch for #{vector_name}"
        expect(frozen_result['final_text']).to eq(expected['final_text']), "#{engine_name} final_text mismatch for #{vector_name}"
      end
    end
  end
end
