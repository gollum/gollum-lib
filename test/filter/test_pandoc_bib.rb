# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::PandocBib" do
  setup do
    @markup = Gollum::Markup.new(mock_page)
    @markup.stubs(:metadata).returns({'bibliography' => 'some.bib', 'csl' => 'chicago.csl', 'link-citations' => true})
    @filter = Gollum::Filter::PandocBib.new(@markup)
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "processing pandoc bibliography metadata" do
    content = 'Test'
    assert_equal content, filter(content)
    GitHub::Markup::Markdown.stubs(:implementation_name).returns('pandoc-ruby')
    assert_match /^---.*link-citations:.*bibliography:.*#{File.expand_path(testpath('some.bib'))}.*csl:.*#{File.expand_path(testpath('chicago.csl'))}.*---.*Test/m, filter(content)

    MockWiki.any_instance.stubs(:repo_is_bare).returns(true)
    sha = MockWiki.new.file(nil).sha
    assert_match /^---.*link-citations:.*bibliography:.*#{sha}.bib.*csl:.*#{sha}.csl.*---.*Test/m, filter(content)
  end
end
