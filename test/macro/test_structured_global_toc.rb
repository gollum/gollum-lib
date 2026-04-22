require_relative '../helper'
require_relative '../wiki_factory'
require 'pry'
require 'pp'

context 'StructuredGlobalToc' do
  setup do
    @wiki, @path, @teardown = WikiFactory.create 'examples/test.git'

    @wiki.write_page('home', :markdown, "home")
    @wiki.write_page('very_very_long_page_name', :markdown, "home")
    @wiki.write_page('hier/page', :markdown, "hier page")
    @wiki.write_page('hier/ar/chy', :markdown, "hierarchy")
    @wiki.write_page('hier/and/there', :markdown, "hier and there")
    @wiki.write_page('folder/page', :markdown, "folder page")
    @wiki.write_page('toc', :markdown, "<<StructuredGlobalTOC()>>")

    @page = @wiki.pages.detect { |page| page.url_path == 'hier/and/there.md' }

    @macro = Gollum::Macro::StructuredGlobalTOC.new(@wiki, @page)
  end

  teardown do
    @teardown.call
  end

  test 'empty wiki' do
    wiki, _path, teardown = WikiFactory.create 'examples/empty.git'
    macro = Gollum::Macro::StructuredGlobalTOC.new(wiki, wiki.pages.first)
    assert_equal("<div class='toc' style='cursor: pointer'>" \
                 "<div class='toc-title'>Global Table of Contents</div></div>",
                 macro.render)
  ensure
    teardown.call
  end

  test 'page grouping' do
    groups = @macro.send(:page_groups)
    paths = extract_paths(groups)
    assert_equal({ nil => ["home.md",
                           "toc.md",
                           "very_very_long_page_name.md"]}, paths[0])
    assert_equal({ "folder" => [
                     { nil => ["folder", "page.md"]}
                   ] }, paths[1])
    assert_equal({ "hier" => [
                     {nil => ["hier", "page.md"]},
                     {"and" => [{nil=>["hier", "and", "there.md"]}]},
                     {"ar" => [{nil=>["hier", "ar", "chy.md"]}]}
                   ] }, paths[2])
  end

  test 'html generation' do
    toc_html = @macro.render
    toc = Nokogiri::HTML toc_html

    top_level = toc.xpath('//div/ul/li')
    # page entries first
    assert_equal('Home', top_level[0].xpath('a').text)
    assert_equal('Toc', top_level[1].xpath('a').text)
    assert_equal('Very Very Long Pag…', top_level[2].xpath('a').text)
    assert_equal('Very Very Long Page Name',
                 top_level[2].xpath('a/span').first['title'])

    # folders then
    folder = top_level[3].xpath('span').first
    assert_equal('▸ Folder', folder.text)
    assert_equal('toggle-button', folder['class'])
    assert_equal('toc_1', folder['data-target'])
    content = toc.xpath("//*[@id='toc_1']").first
    assert_equal('display:none;', content['style'])
    assert_equal('Page', content.text)

    hier = top_level[4].xpath('span').first
    assert_equal('▾ Hier', hier.text)
    assert_equal('toggle-button', hier['class'])
    assert_equal('toc_2', hier['data-target'])

    content = toc.xpath("//*[@id='toc_2']").first
    assert_equal('', content['style'])
    children = content.xpath('*//a | *//span').map {|e| e.text }
    assert_equal(["Page", "▾ And", "There", "▸ Ar", "Chy"], children)
  end

  test 'javascript' do
    javascript = @macro.javascript
    assert_instance_of(String, javascript)
    assert_match(%r{^document.addEventListener\('DOMContentLoaded', function\(\)}, javascript)
  end

  def extract_paths(pages)
    return pages.map do |a, b|
      tupple = if a == nil
                 [a, b.flat_map { |b| b.path }]
               else
                 [a, extract_paths(b) ]
               end
      Hash[*tupple]
    end
  end
end
