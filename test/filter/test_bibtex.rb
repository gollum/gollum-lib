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
    ::CSL::Locale.root = testpath(['examples', 'bibtex', 'locales'])
  end

  teardown do
    # Reset
    ::CSL::Locale.root = '/usr/local/share/csl/locales'
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "no bibtex without valid style file" do
    @markup.stubs(:metadata).returns({'csl' => 'chicago-author-date.csl'})
    result = filter(@content)
    assert_equal true, !!@markup.metadata
    assert_match /Could not render/, @markup.metadata['errors'].first
    assert_equal result, filter(@content)
  end

  test "no bibtex when rendering gems unavailable" do
    Gollum::MarkupRegisterUtils.stubs(:gems_exist?).returns(false)
    assert_equal @content, filter(@content)
  end

  test "bibtex with commited style file" do
    filestub =  OpenStruct.new(
      :sha => 'a35311d46dcd49c2ab63ad9bcbcf16254ac53142',
      :raw_data => File.read(testpath(['examples', 'bibtex', 'csl', 'chicago-author-date.csl']))
    )
    @markup.stubs(:metadata).returns({'csl' => 'chicago-author-date.csl'})
    MockWiki.any_instance.stubs(:file).with('chicago-author-date.csl').returns(filestub)
    assert_equal @chicago, filter(@content)
  end

  test "bibtex with commited locale" do
    filestub =  OpenStruct.new(
      :sha => 'a35311d46dcd49c2ab63ad9bcbcf16254ac53142',
      :raw_data => File.read(testpath(['examples', 'bibtex', 'locales', 'locales-en-GB.xml']))
    )
    @markup.stubs(:metadata).returns({'locale' => 'locales-en-GB.xml'})
    MockWiki.any_instance.stubs(:file).with('locales-en-GB.xml').returns(filestub)
    begin
      ::CSL::Locale.root = '/usr/local/share/csl/locales'
      ::CSL::Style.root = testpath(['examples', 'bibtex', 'csl'])
      assert_equal @apa, filter(@content)
    ensure
      ::CSL::Style.root = '/usr/local/share/csl/styles'
      ::CSL::Locale.root = testpath(['examples', 'bibtex', 'locales'])
    end
  end

  test "bibtex with external style file" do
    MockWiki.any_instance.stubs(:file).returns(nil)
    begin
      ::CSL::Style.root = testpath(['examples', 'bibtex', 'csl'])
      assert_equal @apa, filter(@content)
      assert_equal @apa, filter(@content)
      assert_equal @apa, filter("---\nvalid: false---\n#{@content}INVALID\nBIBTEX\n#Some More Invalid Bibtex")
    ensure 
      ::CSL::Style.root = '/usr/local/share/csl/styles'
    end
  end
end
