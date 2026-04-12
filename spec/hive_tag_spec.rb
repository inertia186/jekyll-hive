require 'spec_helper'
require 'tmpdir'
require 'stringio'
require 'json'
require 'logger'

# Intentionally outside spec/fixtures/vcr_cassettes so cassette cleanup tasks do not remove it.
LEGACY_CACHE_FIXTURE = File.expand_path('fixtures/legacy_cache_entry.html', __dir__)
V2_CACHE_SAMPLE_FIXTURE = File.expand_path('fixtures/v2_cache_entry_hiveio_announcing_the_launch_of_hive_blockchain.html', __dir__)
V2_DOCUMENTATION_POST_FIXTURE = File.expand_path('fixtures/v2_cache_entry_inertia_jekyllhive_v110.html', __dir__)

describe(Jekyll::Hive::HiveTag) do
  HAFBE_FIXTURES = {
    'inertia/kinda-spooky' => 'hafbe_post_inertia_kinda_spooky.json',
    'stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020' => 'hafbe_post_stemgeeks_177.json'
  }.freeze
  HOWO_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_howo_core_dev_meeting_42_history.json', __dir__)
  HOWO_34_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_howo_core_dev_meeting_34_history.json', __dir__)
  HOWO_19_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_howo_hive_core_developer_meeting_19_history.json', __dir__)
  RUBEN_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_rubencress_help_with_hive_getting_added_to_wikipedia_history.json', __dir__)
  KEYS_DEFENDER_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_keys-defender_phishing_on_hive_no_more_solution_for_all_frontends_history.json', __dir__)
  KEYCHAIN_HISTORY_FIXTURE = File.expand_path('fixtures/hafbe_post_keychain_hive_keychain_development_proposal_2_history.json', __dir__)

  describe Jekyll::Hive::HafbeClient do
    let(:client) { described_class.new(api_url: 'https://example.test/hafbe-api') }

    it 'reconstructs the real howo hotspot fixture cleanly with decoded markdown content while preserving the current source-history mention text' do
      payload = JSON.parse(File.read(HOWO_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Core dev meeting #42')
      expect(post['body']).to start_with("\n![social_hive_light.jpg](https://files.peakd.com/file/peakd-hive/howo/")
      expect(post['body']).to include("\n\nHello,\n\nI'm really sorry about the lack of video")
      expect(post['body']).to include("There's then a lot of discussions between @arcage and @blocktrades")
      expect(post['body']).not_to include('@arcange')
      expect(post['body']).not_to include('%0A')
      expect(post['created']).to eq('2022-11-07T22:42:45')
    end

    it 'reconstructs the latest revision for the real rubencress hotspot fixture with decoded text' do
      payload = JSON.parse(File.read(RUBEN_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Help with Hive getting added to Wikipedia')
      expect(post['body']).to include('1. History of Hive')
      expect(post['body']).to include("Cheers,\nRuben")
      expect(post['body']).to include("ps; I'll be updating this page as I update the Wikipedia page.")
      expect(post['body']).not_to include('%0A')
      expect(post['created']).to eq('2022-11-04T18:52:57')
    end

    it 'reconstructs real howo core-dev-meeting-34 history without encoded tail corruption' do
      payload = JSON.parse(File.read(HOWO_34_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Core dev meeting #34')
      expect(post['body']).to include("\n\n@howo \n\n![](https://i.imgur.com/oPJ63jA.png)")
      expect(post['body']).to include('<center><sup>You can vote for our witness directly using Hivesigner')
      expect(post['body']).not_to include('%0A')
      expect(post['created']).to eq('2022-02-15T18:37:00')
    end

    it 'reconstructs real howo hive-core-developer-meeting-19 history while preserving the current source-history topic-tags oddity' do
      payload = JSON.parse(File.read(HOWO_19_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Hive core developer meeting #19')
      expect(post['body']).to include('## Hivemind Communities type 2/3 and account level mutes [hivemind#125](https://gitlab.syncad.com/hive/hivemind/-/issues/125) / [hivemind#145](https://gitlab.syncad.com/hive/hivemind/-/issues/145)')
      expect(post['body']).to include('(hivemind#148)[https://gitlab.syncad.com/hive/hivemind/-/issues/148]')
      expect(post['body']).not_to include('[hivemind#148](https://gitlab.syncad.com/hive/hivemind/-/issues/148)')
      expect(post['body']).not_to include('%0A')
      expect(post['created']).to eq('2021-03-16T00:09:57')
    end

    it 'reconstructs the keys-defender history without the previous encoded corruption' do
      payload = JSON.parse(File.read(KEYS_DEFENDER_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Phishing on Hive? No more. Solution for all Frontends.')
      expect(post['body']).to include('leave the user experience unaffected.')
      expect(post['body']).to include('<u><b>As a matter of fact, this is what I worked on in the past few days.</b></u>')
      expect(post['body']).not_to include('%0A')
      expect(post['created']).to eq('2021-03-17T07:06:12')
    end

    it 'still leaves one real keychain history specimen with encoded remnants even after proper patch application' do
      payload = JSON.parse(File.read(KEYCHAIN_HISTORY_FIXTURE))

      post = client.send(:normalize_post, payload)

      expect(post['title']).to eq('Hive Keychain Development Proposal #2')
      expect(post['body']).to include('[PeakD](https://peakd.com/me/proposals/140)')
      expect(post['body']).to include('[HiveSigner](https://hivesigner.com/sign/update-proposal-votes?proposal_ids=%5B140%5D&approve=true)')
      expect(post['body']).to include('%5B140%5D')
      expect(post['created']).to eq('2020-11-09T07:10:57')
    end
  end

  let(:doc) { doc_with_content(content) }
  let(:content) { "{% hive #{slug} %}" }
  let(:output) do
    doc.content = content
    doc.output = Jekyll::Renderer.new(doc.site, doc).run
  end
  let(:site_config_overrides) { {} }

  before do
    allow_any_instance_of(described_class).to receive(:cache_dir_path).and_return(cache_dir)
    allow_any_instance_of(Jekyll::Hive::HafbeClient).to receive(:fetch_post) do |_instance, author, permlink|
      slug = "#{author}/#{permlink}"
      fixture_name = HAFBE_FIXTURES.fetch(slug)
      payload = JSON.parse(File.read(File.expand_path("fixtures/#{fixture_name}", __dir__)))
      Jekyll::Hive::HafbeClient.new.send(:normalize_post, payload)
    end
    allow(URI).to receive(:open) do |url|
      case url
      when 'https://stemgeeks.net/@stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020'
        StringIO.new('<html><head><link rel="canonical" href="https://stemgeeks.net/@stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020"></head></html>')
      when 'https://hive.blog/governance/@inertia/kinda-spooky'
        StringIO.new('<html><head><link rel="canonical" href="https://hive.blog/governance/@inertia/kinda-spooky"></head></html>')
      when 'https://hive.blog/@inertia/kinda-spooky'
        StringIO.new('<html><head><link rel="canonical" href="https://hive.blog/governance/@inertia/kinda-spooky"></head></html>')
      else
        raise "Unexpected URI.open in spec: #{url}"
      end
    end
  end

  let(:cache_dir) { Dir.mktmpdir('jekyll-hive-cache') }

  def doc_with_content(_content, opts = {})
    my_site = site(site_config_overrides.merge(opts))
    Jekyll::Document.new(source_dir('_test/doc.md'), { :site => my_site, :collection => collection(my_site) })
  end

  after do
    FileUtils.remove_entry(cache_dir) if File.exist?(cache_dir)
  end

  context 'valid slug' do
    context 'with author and permlink' do
      let(:slug) { 'inertia/kinda-spooky' }
      
      it 'produces the correct paragraph' do
        expect(output).to include('Late Monday night (pacific), we were observing the hardfork witness majority')
        expect(output).to include('https://hive.blog/governance/@inertia/kinda-spooky')
      end
    end
    
    context 'with author and permlink providing canonical url' do
      let(:slug) { 'stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020' }
      
      it 'produces the correct paragraph' do
        expect(output).to include('As we have done since the beginning, we burned another 10% chunk of the STEM sell wall.')
        expect(output).to include('https://stemgeeks.net/@stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020')
      end
    end
  end
  
  context 'legacy cache detection' do
    let(:slug) { 'inertia/kinda-spooky' }
    let(:content) { '{% hive inertia/kinda-spooky %}{% hive inertia/kinda-spooky %}' }

    it 'warns once per build when legacy cache entries are detected' do
      FileUtils.mkdir_p(cache_dir)
      File.write(File.join(cache_dir, 'inertia-kinda-spooky'), File.read(LEGACY_CACHE_FIXTURE))

      rendered_output = nil
      original_stderr = $stderr
      captured_stderr = StringIO.new
      $stderr = captured_stderr

      begin
        rendered_output = output
      ensure
        $stderr = original_stderr
      end

      expect(captured_stderr.string).to include('Delete .jekyll-hive-cache and rebuild')
      expect(captured_stderr.string.scan('Delete .jekyll-hive-cache and rebuild').count).to eq(1)
      expect(rendered_output).to include('Legacy cached output')
      expect(rendered_output).to include('https://unpkg.com/steem-content-renderer')
    end

    it 'does not warn for cache entries that merely contain example script/style code' do
      FileUtils.mkdir_p(cache_dir)
      File.write(
        File.join(cache_dir, 'inertia-kinda-spooky'),
        <<~HTML
          <div class="hive-post-embed" data-hive-author="inertia" data-hive-permlink="kinda-spooky">
            <div id="content-inertia-kinda-spooky" class="hive-post-embed__content" data-hive-render-target="true">
              <pre><code>&lt;script&gt;alert('hello');&lt;/script&gt;
              &lt;style&gt;.demo { color: red; }&lt;/style&gt;</code></pre>
            </div>
            <footer class="hive-post-embed__source">
              <span class="hive-post-embed__source-label">Source:</span>
              <a href="https://hive.blog/governance/@inertia/kinda-spooky">Kinda Spooky</a>
              by
              <a href="https://hive.blog/@inertia">@inertia</a>
            </footer>
          </div>
        HTML
      )

      rendered_output = nil
      original_stderr = $stderr
      captured_stderr = StringIO.new
      $stderr = captured_stderr

      begin
        rendered_output = output
      ensure
        $stderr = original_stderr
      end

      expect(captured_stderr.string).not_to include('Delete .jekyll-hive-cache and rebuild')
      expect(rendered_output).to include('&lt;script&gt;alert(')
      expect(rendered_output).to include('hive-post-embed__content')
    end

    it 'does not classify a real v2 cache entry from hivedocs.info as legacy' do
      cache_value = File.binread(V2_CACHE_SAMPLE_FIXTURE)
      tag = described_class.allocate

      expect(tag.send(:legacy_cache_entry?, cache_value)).to be(false)
      expect(cache_value).to include('hive-post-embed__content')
      expect(cache_value).to include('data-hive-render-target="true"')
      expect(cache_value).to include('Announcing the Launch of Hive Blockchain')
    end

    it 'does not classify a v2 cache entry as legacy just because the post body documents old jekyll-hive usage' do
      cache_value = File.binread(V2_DOCUMENTATION_POST_FIXTURE)
      tag = described_class.allocate

      expect(tag.send(:legacy_cache_entry?, cache_value)).to be(false)
      expect(cache_value).to include('data-hive-render-target="true"')
      expect(cache_value).to include('https://unpkg.com/steem-content-renderer')
      expect(cache_value).to include('Jekyll::Hive v1.1.0')
    end
  end

  context 'invalid slug' do
    context 'no slug present' do
      let(:slug) { '' }

      it 'raises an error' do
        allow(Jekyll.logger).to receive(:error)
        allow(Jekyll.logger).to receive(:warn)

        expect { output }.to raise_error(ArgumentError)
      end
    end
  end
end
