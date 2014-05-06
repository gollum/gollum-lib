# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

def utf8(str)
  str.respond_to?(:force_encoding) ? str.force_encoding('utf-8') : str
end

context "Unicode Support" do
  setup do
    @path = cloned_testpath("examples/revert.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "create and read non-latin page with anchor" do
    @wiki.write_page("test", :markdown, "# 한글")

    page = @wiki.page("test")
    assert_equal Gollum::Page, page.class
    assert_equal "# 한글", utf8(page.raw_data)

    # markup.rb
    doc     = Nokogiri::HTML page.formatted_data
    h1s     = doc / :h1
    h1      = h1s.first
    anchors = h1 / :a
    assert_equal 1, h1s.size
    assert_equal 1, anchors.size
    assert_equal '#한글',  anchors[0]['href']
    assert_equal  '한글',  anchors[0]['id']
    assert_equal 'anchor', anchors[0]['class']
    assert_equal '',       anchors[0].text
  end

  def check_h1 text, page
      @wiki.write_page(page, :markdown, "# " + text)

      page = @wiki.page(page)
      assert_equal Gollum::Page, page.class
      assert_equal '# ' + text, utf8(page.raw_data)

      output = page.formatted_data

      # UTF-8 headers should not be encoded.
      assert_match /<h1>#{text}<\/h1>/,   output
  end

  test "create and read non-latin page with anchor" do
    # href="#한글"
    # href="#%ED%95%9C%EA%B8%80"
    check_h1 '한글', '1'
    # href="#Synhtèse"
    # href="#Synht%C3%A8se"
    check_h1 'Synhtèse', '2'
  end

  test "create and read non-latin page with anchor 2" do
    @wiki.write_page("test", :markdown, "## \"La\" faune d'Édiacara")

    page = @wiki.page("test")
    assert_equal Gollum::Page, page.class
    assert_equal "## \"La\" faune d'Édiacara", utf8(page.raw_data)

    # markup.rb test: ', ", É
    doc     = Nokogiri::HTML page.formatted_data
    h2s     = doc / :h2
    h2      = h2s.first
    anchors = h2 / :a
    assert_equal 1, h2s.size
    assert_equal 1, anchors.size
    assert_equal %q(#%22La%22-faune-d'Édiacara), anchors[0]['href']
    assert_equal %q(%22La%22-faune-d'Édiacara),  anchors[0]['id']
    assert_equal 'anchor',                 anchors[0]['class']
    assert_equal '',                       anchors[0].text
  end

  test "unicode with existing format rules" do
    @wiki.write_page("test", :markdown, "# 한글")
    assert_equal @wiki.page("test").path, @wiki.page("test").path
  end
end
