# ~*~ encoding: utf-8 ~*~
require File.expand_path('../helper', __FILE__)
require File.expand_path('../wiki_factory', __FILE__)

class Gollum::Macro::ListArgs < Gollum::Macro
  def render(*args)
    args.map { |a| "@#{a}@" }.join("\n")
  end
end

class Gollum::Macro::ListNamedArgs < Gollum::Macro
  def render(opts)
    opts.map { |k,v| "@#{k} = #{v}@" }.join("\n")
  end
end

context "Macros" do
  setup do
    @wiki, @path, @teardown = WikiFactory.create 'examples/test.git'
  end

  teardown do
    @teardown.call
  end


  test "Macro's are escapable" do
    @wiki.write_page("MacroEscapeText", :markdown, "'<<AllPages()>>", commit_details)
    assert_match "<p>&lt;&lt;AllPages()&gt;&gt;</p>", @wiki.pages[0].formatted_data
  end

  test "Missing macro provides missing macro output" do
    @wiki.write_page("NonExistentPage", :markdown, "<<NonExistentMacro()>>", commit_details)
    assert_match(/Unknown macro: NonExistentMacro/, @wiki.pages[0].formatted_data)
  end

  test "AllPages macro does something interesting" do
    @wiki.write_page("AllPagesMacroPage", :markdown, "<<AllPages()>>", commit_details)
    assert_match(/<li>AllPagesMacroPage/, @wiki.pages[0].formatted_data)
  end

  test "GlobalTOC macro displays global table of contents" do
    @wiki.write_page("GlobalTOCMacroPage", :markdown, "<<GlobalTOC(Pages in this Wiki)>>", commit_details)
    assert_match /<div class="toc">(.*)Pages in this Wiki(.*)<li><a href="\/GlobalTOCMacroPage.md" rel="nofollow">GlobalTOCMacroPage.md/, @wiki.pages[0].formatted_data
  end

  test "Navigation macro displays table of contents for subpath" do
    @wiki.write_page("NavigationMacroPage", :markdown, "<<Navigation()>>", commit_details)
    @wiki.write_page("ZZZZ/A", :markdown, "content", commit_details)
    assert_match /<div class="toc"><div class="toc-title">Navigate this directory<\/div><ul><li><a href="\/NavigationMacroPage.md" rel="nofollow">NavigationMacroPage.md<\/a><\/li><li><a href="\/ZZZZ\/A\.md" rel="nofollow">ZZZZ\/A\.md<\/a><\/li><\/ul><\/div>/, @wiki.pages[0].formatted_data
  end

  test "Navigation macro does not show full path if parameter full_path is set to false" do
    # This is also a regression test against https://github.com/gollum/gollum-lib/issues/446
    @wiki.write_page("NavigationMacroPage", :markdown, '<<Navigation("My TOC", "ZZZZ", false)>>', commit_details)
    @wiki.write_page("ZZZZ/A", :markdown, "content", commit_details)
    assert_match /<div class="toc"><div class="toc-title">My TOC<\/div><ul><li><a href="\/ZZZZ\/A\.md" rel="nofollow">A\.md<\/a><\/li><\/ul><\/div>/, @wiki.pages[0].formatted_data
  end

  test "Series macro displays series links with and without series prefix" do
    @wiki.write_page("test-series1", :markdown, "<<Series(test)>>", commit_details)
    testseries1 = @wiki.page("test-series1")
    @wiki.write_page("test-series2", :markdown, "<<Series(test)>>", commit_details)
    testseries2 = @wiki.page("test-series2")

    # Now create pages that are alphanumerically earlier, but don't match the 'test' prefix
    @wiki.write_page("ta-series1", :markdown, "<<Series()>>", commit_details)
    taseries1 = @wiki.page("ta-series1")
    @wiki.write_page("ta-series2", :markdown, "<<Series()>>", commit_details)
    taseries2 = @wiki.page("ta-series2")

    assert_match /Next(.*)test-series2/, testseries1.formatted_data
    assert_no_match /Previous/, testseries1.formatted_data
    assert_match /Next(.*)ta-series2/, taseries1.formatted_data
    assert_match /Previous(.*)ta-series1/, taseries2.formatted_data
    assert_match /Previous(.*)test-series1/, testseries2.formatted_data

    @wiki.write_page("test-series3", :markdown, "<<SeriesEnd(test)>>", commit_details)
    testseries3 = @wiki.page("test-series3")
    @wiki.write_page("test-series4", :markdown, "<<SeriesStart(test)>>", commit_details)
    testseries4 = @wiki.page("test-series4")
    assert_no_match /Previous/, testseries4.formatted_data
  end

  test "Series macro in subpage" do
    @wiki.write_page("test-series1", :markdown, "test1", commit_details)
    @wiki.write_page("test-series2", :markdown, "test2", commit_details)
    @wiki.write_page("_Footer", :markdown, "<<Series(test)>>", commit_details)
    test1 = @wiki.page("test-series1")
    test2 = @wiki.page("test-series2")

    assert_match /Next(.*)test-series2/, test1.footer.formatted_data
    assert_match /Previous(.*)test-series1/, test2.footer.formatted_data
  end

  
  test "ListArgs with no args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs()>>", commit_details)
    assert_no_match(/@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with a single empty quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("")>>', commit_details)
    assert_match(/@@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with a single non-quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs(foo)>>", commit_details)
    assert_match(/@foo@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with several single non-quoted args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs(foo, bar,baz)>>", commit_details)
    assert_match(/@foo@/, @wiki.pages[0].formatted_data)
    assert_match(/@bar@/, @wiki.pages[0].formatted_data)
    assert_match(/@baz@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with a single quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz")>>', commit_details)
    assert_match(/@foo, bar, and baz@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with several quoted args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz", "wombat", "xyzzy")>>', commit_details)
    assert_match(/@foo, bar, and baz@/, @wiki.pages[0].formatted_data)
    assert_match(/@wombat@/, @wiki.pages[0].formatted_data)
    assert_match(/@xyzzy@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with quoted parens" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs(foo, "(bar)")>>', commit_details)
    assert_match(/@foo@/, @wiki.pages[0].formatted_data)
    assert_match(/@\(bar\)@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with escaped quotation mark in quoted args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("Goodbye \"cruel\" world")>>', commit_details)
    assert_match(/@Goodbye "cruel" world@/, @wiki.pages[0].formatted_data)
  end

  test "ListArgs with a mix or arg styles" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz", wombat, funny things)>>', commit_details)
    assert_match(/@foo, bar, and baz@/, @wiki.pages[0].formatted_data)
    assert_match(/@wombat@/, @wiki.pages[0].formatted_data)
    assert_match(/@funny things@/, @wiki.pages[0].formatted_data)
  end
  
  test "Args parser doesn't overstep its boundaries" do
    @wiki.write_page("MultiMacroPage", :markdown, "<<ListArgs(Foo)>>\n\n<<NonExistentMacro()>>", commit_details)
    assert_match(/@Foo@/, @wiki.pages[0].formatted_data)
    assert_match(/Unknown macro: NonExistentMacro/, @wiki.pages[0].formatted_data)
  end

  test "Args parser handles named args" do
    @wiki.write_page("ListNamedArgsPage", :markdown, "<<ListNamedArgs(xyzzy=\"Foo\")>>", commit_details)
    assert_match(/@xyzzy = Foo@/, @wiki.pages[0].formatted_data)
  end

  test "Video macro given a name of a file displays an html5 video tag" do
    file = "/Uploads/foo.mp4"
    @wiki.write_page("VideoTagTest", :markdown, "<<Video(#{file})>>", commit_details)
    assert_match /<video (.*) src="#{file}"(.*)> (.*)<\/video>/, @wiki.pages[0].formatted_data
  end 

  test "Audio macro given a name of a file displays an audio tag" do
    file = "/Uploads/foo.mp3"
    @wiki.write_page("AudioTagTest", :markdown, "<<Audio(#{file})>>", commit_details)
    assert_match /<audio (.*) src="#{file}"(.*)> (.*)<\/audio>/, @wiki.pages[0].formatted_data
  end

  test "Icon macro given a symbol renders gollum-icon div with data-gollum-icon attribute" do
    @wiki.write_page("IconMacroPage", :markdown, '<<Icon("globe")>>', commit_details)
    assert_match /<div class=\"gollum-icon\".*data-gollum-icon=\"globe\".*/, @wiki.pages[0].formatted_data
  end

  test "Flash macro given a type and icon name renders gollum-flash with data-* attributes" do
    @wiki.write_page("FlashMacroPage", :markdown, '<<Flash("Not all those who wander are lost", "bell", "success")>>', commit_details)
    assert_match /<div class=\"flash flash-success my-2\".*data-gollum-icon=\"bell\".*/, @wiki.pages[0].formatted_data
  end

  test "Note macro given a string displays a regular flash message box" do
    @wiki.write_page("NoteMacroPage", :markdown, '<<Note("Did you know Bilbo is a Hobbit?")>>', commit_details)
    assert_match /<div class=\"flash gollum-note my-2\">.*Did you know Bilbo.*/, @wiki.pages[0].formatted_data
  end

  test "Warn macro given a string displays a flash-warning message box" do
    @wiki.write_page("WarnMacroPage", :markdown, '<<Warn("Be careful not to mention hobbits in conversation too much.")>>', commit_details)
    assert_match /<div class=\"flash flash-warn gollum-warning my-2\">.*Be careful.*/, @wiki.pages[0].formatted_data
  end

  test "Macro errors are reported in place in a flash-error message box" do
    @wiki.write_page("IconMacroPage", :markdown, '<<Note("foobar", 64, 64)>>', commit_details)
    assert_match /<div class=\"flash flash-error gollum-macro-error my-2\">Macro Error for Note: wrong number of arguments.*/, @wiki.pages[0].formatted_data
  end

  test "Macros escape HTML" do
    @wiki.write_page("AudioXSSTest", :markdown, '<<Audio(a"></audio><input>)>>', commit_details)
    assert_not_match /<input/, @wiki.pages[0].formatted_data
  end

  test "Note macro renders HTML code" do
    @wiki.write_page("HTMLNoteMacroPage", :markdown, '<<Note("<span>test</span>")>>', commit_details)
    assert_match /<div class=\"flash gollum-note my-2\".*<span>test<\/span>.*/, @wiki.pages[0].formatted_data
  end

  test "Series macro escapes page names" do
    @wiki.write_page("test-1", :markdown, "test1", commit_details)
    @wiki.write_page("test-2<span>", :markdown, "test2", commit_details)
    @wiki.write_page("_Footer", :markdown, "<<Series(test)>>", commit_details)
    assert_match /Next(.*)test-2&lt;span&gt;/, @wiki.page("test-1").footer.formatted_data
  end

  test "Control attributes for Audio and Video are not sanitized" do
    @wiki.write_page("AudioTagTest", :markdown, "<<Audio(foo)>>\n<<Video(bar)>>", commit_details)
    # The Macros must return controls=true until https://github.com/flavorjones/loofah/issues/242 is resolved
    assert_match /<audio (.*)controls(.*)>(.*)<video (.*)controls(.*)>/m, @wiki.pages[0].formatted_data
  end
end
