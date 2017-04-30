# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::BibTeX" do
  setup do
    @content = "@book{tolkien2012lord,\n  title={The Lord of the Rings: One Volume},\n  author={Tolkien, John Ronald Reuel},\n  year={2012},\n  publisher={Houghton Mifflin Harcourt}\n}\n" 
    @apa = "Tolkien, J. R. R. (2012). <i>The Lord of the Rings: One Volume</i>. Houghton Mifflin Harcourt."
    @chicago = "Tolkien, John Ronald Reuel. 2012. <i>The Lord of the Rings: One Volume</i>. Houghton Mifflin Harcourt."
    @markup = Gollum::Markup.new(mock_page(:bib, @content))
    @filter = Gollum::Filter::BibTeX.new(@markup)
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "processing bibtex" do
    assert_equal @apa, filter(@content)
    assert_equal @apa, filter("---\nvalid: false---\n#{@content}INVALID\nBIBTEX\n#Some More Invalid Bibtex")
    @markup.stubs(:metadata).returns({'bibstyle' => 'chicago-author-date'})
    assert_equal @chicago, filter(@content)
    Gollum::MarkupRegisterUtils.stubs(:gems_exist?).returns(false)
    assert_equal @content, filter(@content)
  end
end
