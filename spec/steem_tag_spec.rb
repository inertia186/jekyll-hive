require 'spec_helper'

describe(Jekyll::Steem::SteemTag) do
  let(:doc) { doc_with_content(content) }
  let(:content) { "{% steem #{slug} %}" }
  let(:output) do
    doc.content = content
    doc.output = Jekyll::Renderer.new(doc.site, doc).run
  end
  
  context 'valid slug' do
    context 'with author and permlink' do
      let(:slug) { 'inertia/kinda-spooky' }
      
      it 'produces the correct paragraph' do
        VCR.use_cassette('valid_slug_content') do
          expect(output).to include('Late Monday night (pacific), we were observing the hardfork witness majority')
          expect(output).to include('https://steemit.com/@inertia/kinda-spooky')
        end
      end
    end
    
    context 'with author and permlink providing canonical url' do
      let(:slug) { 'stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020' }
      
      it 'produces the correct paragraph' do
        VCR.use_cassette('valid_slug_content_with_canonical_url') do
          expect(output).to include('As we have done since the beginning, we burned another 10% chunk of the STEM sell wall.')
          expect(output).to include('https://stemgeeks.net/@stemgeeks/177-000-stem-burned-and-stem-miner-price-increase-in-2020')
        end
      end
    end
  end
  
  context 'invalid slug' do
    context 'no slug present' do
      let(:slug) { '' }
      
      it 'raises an error' do
        expect(-> { output }).to raise_error(ArgumentError)
      end
    end
  end
end
