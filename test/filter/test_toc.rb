# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)
require 'nokogiri'

def get_toc_html(page)
  string = Nokogiri::HTML::DocumentFragment.parse(page.formatted_data).at_css('div.toc > ul').to_s
  string.gsub!(/(?<=\>|\A)[\n\s]+?(?=<|\Z)/, '')
  string
end

context "Gollum::Filter::TOC" do
  setup do
    @path = cloned_testpath('examples/toc.git')
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test 'normal table of contents' do
    page = @wiki.page('Normal.md')
    toc = get_toc_html(page)
    expected_toc = "<ul><li><a href=\"#h1\">H1</a><ul><li><a href=\"#h2\">H2</a><ul><li><a href=\"#h3\">H3</a></li></ul></li><li><a href=\"#h2-1\">H2</a></li></ul></li><li><a href=\"#h1-1\">H1</a></li></ul>"

    assert_equal expected_toc, toc
  end

  test 'one element with omitted H1 and H2 in table of contents' do
    page = @wiki.page('One-Element.md')
    toc = get_toc_html(page)
    expected_toc = "<ul><li><a href=\"#h3\">H3</a></li></ul>"

    assert_equal expected_toc, toc
  end

  test 'no nested structure with omitted H1 in table of contents' do
    page = @wiki.page('List.md')
    toc = get_toc_html(page)
    expected_toc = "<ul><li><a href=\"#h2\">H2</a></li><li><a href=\"#h2-1\">H2</a></li><li><a href=\"#h2-2\">H2</a></li></ul>"

    assert_equal expected_toc, toc
  end

  test 'omit H1 header in table of contents' do
    page = @wiki.page('Omitted-H1.md')
    toc = get_toc_html(page)
    expected_toc = "<ul><li><a href=\"#h2\">H2</a><ul><li><a href=\"#h3\">H3</a><ul><li><a href=\"#h4\">H4</a></li></ul></li><li><a href=\"#h3-1\">H3</a></li></ul></li><li><a href=\"#h2-1\">H2</a></li></ul>"

    assert_equal expected_toc, toc
  end

  test 'omit H1 and H3 headers in table of contents' do
    page = @wiki.page('Omitted-H1-H3.md')
    toc = get_toc_html(page)
    expected_toc = "<ul><li><a href=\"#h2\">H2</a><ul><li><a href=\"#h4\">H4</a><ul><li><a href=\"#h5\">H5</a></li></ul></li><li><a href=\"#h4-1\">H4</a></li></ul></li><li><a href=\"#h2-1\">H2</a></li></ul>"

    assert_equal expected_toc, toc
  end

end
