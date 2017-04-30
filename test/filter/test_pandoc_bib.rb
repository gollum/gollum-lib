# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::PandocBib" do
  setup do
    @markup = Gollum::Markup.new(mock_page)
    @markup.stubs(:metadata).returns({'bibliography' => 'some.bib', 'csl' => 'chicago.csl'})
    @filter = Gollum::Filter::PandocBib.new(@markup)
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "processing pandoc bibliography metadata" do
    content = 'Test'
    assert_equal content, filter(content)
    GitHub::Markup::Markdown.stubs(:implementation_name).returns('pandoc-ruby')
    assert_match /^---.*bibliography:.+.bib.*csl:.+.csl.*---.*Test/m, filter(content)
  end
end
