# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Wiki determines whether or not to use PandocBib filter" do
  test "when pandoc enabled" do
    wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
    assert_equal false, wiki.instance_variable_get(:@filter_chain).include?(:PandocBib)
  end
  
  test "when pandoc not enabled" do
    GitHub::Markup::Markdown.stubs(:implementation_name).returns('pandoc-ruby')
    wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
    assert_equal true, wiki.instance_variable_get(:@filter_chain).include?(:PandocBib)
  end
end

context "Gollum::Filter::PandocBib" do
  setup do
    GitHub::Markup::Markdown.stubs(:implementation_name).returns('pandoc-ruby')
    @markup = Gollum::Markup.new(mock_page)
    @markup.stubs(:metadata).returns({'bibliography' => 'some.bib', 'csl' => 'chicago.csl', 'link-citations' => true})
    @filter = Gollum::Filter::PandocBib.new(@markup)
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "processing pandoc bibliography metadata with non-bare wiki" do
    content = 'Test'
    expected = /^---.*link-citations:.*bibliography:.*#{File.expand_path(testpath('some.bib'))}.*csl:.*#{File.expand_path(testpath('chicago.csl'))}.*---.*Test/m
    assert_match expected, filter(content)
  end

  test "process pandoc bibliography metadata with bare wiki" do
    MockWiki.any_instance.stubs(:repo_is_bare).returns(true)
    content = 'Test'
    sha = MockWiki.new.file(nil).sha
    expected = /^---.*link-citations:.*bibliography:.*#{sha}.bib.*csl:.*#{sha}.csl.*---.*Test/m
    assert_match expected, filter(content)
  end
end