# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Page" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "new page" do
    page = Gollum::Page.new(@wiki)
    assert_nil page.raw_data
    assert_nil page.formatted_data
  end

  test "get existing page" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal Gollum::Page, page.class
    assert page.raw_data =~ /^# Bilbo Baggins\n\nBilbo Baggins/

    expected = "<h1><a class=\"anchor\" id=\"bilbo-baggins\" href=\"#bilbo-baggins\"><i class=\"fa fa-link\"></i></a>Bilbo Baggins</h1>\n\n<p>Bilbo Baggins is the protagonist of The <a class=\"internal present\" href=\"/Hobbit\">Hobbit</a> and also makes a few\nappearances in The Lord of the Rings, two of the most well-known of <a class=\"internal absent\" href=\"/J.+R.+R.+Tolkien\">J. R. R. Tolkien</a>'s fantasy writings. The story of The Hobbit featuring Bilbo is also\nretold from a different perspective in the Chapter The Quest of Erebor in\nUnfinished Tales.</p>\n\n<p>In Tolkien's narrative conceit, in which all the writings of Middle-earth are\n'really' translations from the fictitious volume of The Red Book of Westmarch,\nBilbo is the author of The Hobbit and translator of The Silmarillion.</p>\n\n<p>From <a href=\"http://en.wikipedia.org/wiki/Bilbo_Baggins\">http://en.wikipedia.org/wiki/Bilbo_Baggins</a>.</p>"
    actual   = page.formatted_data
    assert_html_equal expected, actual

    assert_equal 'Bilbo-Baggins.md', page.path
    assert_equal :markdown, page.format
    assert_equal @wiki.repo.commits.first.id, page.version.id

    assert_not_nil page.last_version
    assert_equal page.versions.first.id, page.last_version.id
    assert page.last_version.stats.files.map{|file| file_path = file.first}.include? page.path
  end

  test "getting pages is case insensitive" do
    assert_equal Gollum::Page, @wiki.page('bilbo-baggins').class
  end

  test "do not substitute whitespace for hyphens or underscores (regression test < 5.x)" do
    assert_not_nil @wiki.page('Bilbo-Baggins').path
    assert_nil @wiki.page('Bilbo_Baggins')
    assert_nil @wiki.page('Bilbo Baggins')
  end

  test "get nested page" do
    page = @wiki.page('Eye-Of-Sauron')
    assert_equal 'Mordor/Eye-Of-Sauron.md', page.path
  end

  test "url_path" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal 'Bilbo-Baggins', page.url_path
  end

  test "nested url_path" do
    page = @wiki.page('Eye-Of-Sauron')
    assert_equal 'Mordor/Eye-Of-Sauron', page.url_path
  end

  test "page versions" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal ["ea8114ad3c40b90c536c18fae9ed8d1063b1b6fc", "f25eccd98e9b667f9e22946f3e2f945378b8a72d", "5bc1aaec6149e854078f1d0f8b71933bbc6c2e43"],
                 page.versions.map { |v| v.id }
  end

  test "page versions across renames" do
    page = @wiki.page 'My-Precious'
    assert_equal ['60f12f4254f58801b9ee7db7bca5fa8aeefaa56b', '94523d7ae48aeba575099dd12926420d8fd0425d'],
                 page.versions(:follow => true).map { |v| v.id }
  end

  test "page versions without renames" do
    page = @wiki.page 'My-Precious'
    assert_equal ['60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'],
                 page.versions(:follow => false).map { |v| v.id }
  end

  test "specific page version" do
    page = @wiki.page('Bilbo-Baggins', 'fbabba862dfa7ac35b39042dd4ad780c9f67b8cb')
    assert_equal 'fbabba862dfa7ac35b39042dd4ad780c9f67b8cb', page.version.id
  end

  test "no page match" do
    assert_nil @wiki.page('I do not exist')
  end

  test "no version match" do
    assert_nil @wiki.page('Bilbo-Baggins', 'I do not exist')
  end

  test "no non-page match" do
    assert_nil @wiki.page('Data')
  end

  test "match with page extension" do
    page = @wiki.page 'Bilbo-Baggins.textile'
    assert_nil page
    page = @wiki.page 'Bilbo-Baggins.md'
    assert_equal Gollum::Page, page.class
  end

  test "title from filename with normal contents 1" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal 'Bilbo-Baggins', page.title
  end

  test "top level header" do
    header = @wiki.page('Home').header
    assert_equal "Hobbits\n", header.raw_data
    assert_equal "_Header.md", header.path
  end

  test "nested header" do
    header = @wiki.page('Eye-Of-Sauron').header
    assert_equal "Sauron\n", header.raw_data
    assert_equal "Mordor/_Header.md", header.path
  end

  test "header itself" do
    header = @wiki.page("_Header")
    assert_nil header.header
    assert_nil header.footer
    assert_nil header.sidebar
  end

  test "top level footer" do
    footer = @wiki.page('Home').footer
    assert_equal 'Lord of the Rings wiki', footer.raw_data
    assert_equal '_Footer.md', footer.path
  end

  test "nested footer" do
    footer = @wiki.page('Eye-Of-Sauron').footer
    assert_equal "Ones does not simply **walk** into Mordor!\n", footer.raw_data
    assert_equal "Mordor/_Footer.md", footer.path
  end

  test "footer itself" do
    footer = @wiki.page("_Footer")
    assert_nil footer.header
    assert_nil footer.footer
    assert_nil footer.sidebar
  end

  test "top level sidebar" do
    sidebar = @wiki.page('Home').sidebar
    assert_equal 'Lord of the Rings wiki', sidebar.raw_data
    assert_equal '_Sidebar.md', sidebar.path
  end

  test "nested sidebar" do
    sidebar = @wiki.page('Eye-Of-Sauron').sidebar
    assert_equal "Ones does not simply **walk** into Mordor!\n", sidebar.raw_data
    assert_equal "Mordor/_Sidebar.md", sidebar.path
  end

  test "sidebar itself" do
    sidebar = @wiki.page("_Sidebar")
    assert_nil sidebar.header
    assert_nil sidebar.footer
    assert_nil sidebar.sidebar
  end

  test "normalize_dir" do
    assert_equal "", Gollum::BlobEntry.normalize_dir("")
    assert_equal "", Gollum::BlobEntry.normalize_dir(".")
    assert_equal "", Gollum::BlobEntry.normalize_dir("/")
    assert_equal "", Gollum::BlobEntry.normalize_dir("c:/")
    assert_equal "/foo", Gollum::BlobEntry.normalize_dir("foo")
    assert_equal "/foo", Gollum::BlobEntry.normalize_dir("/foo")
  end

  test "tell whether metadata should be rendered" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal false, page.display_metadata?

    page.stubs(:metadata).returns({'race' => 'hobbit'})
    assert_equal true, page.display_metadata?

    page.stubs(:metadata).returns({'title' => 'Only override title'})
    assert_equal false, page.display_metadata?

    page.stubs(:metadata).returns({'title' => 'Override title and have some more metadata', 'race' => 'hobbit'})
    assert_equal true, page.display_metadata?

    page.stubs(:metadata).returns({
      'title' => 'Override title and have some more metadata but explicitly turn off displaying of metadata',
      'race' => 'hobbit',
      'display_metadata' => false
      })
    assert_equal false, page.display_metadata?
  end

end

context "with a checkout" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "get existing page with symbolic link" do
    page = @wiki.page("Hobbit")
    assert_equal Gollum::Page, page.class
    assert page.raw_data =~ /^# Bilbo Baggins\n\nBilbo Baggins/

    expected = "<h1><a class=\"anchor\" id=\"bilbo-baggins\" href=\"#bilbo-baggins\"><i class=\"fa fa-link\"></i></a>Bilbo Baggins</h1>\n\n<p>Bilbo Baggins is the protagonist of The <a class=\"internal present\" href=\"/Hobbit\">Hobbit</a> and also makes a few\nappearances in The Lord of the Rings, two of the most well-known of <a class=\"internal absent\" href=\"/J.+R.+R.+Tolkien\">J. R. R. Tolkien</a>'s fantasy writings. The story of The Hobbit featuring Bilbo is also\nretold from a different perspective in the Chapter The Quest of Erebor in\nUnfinished Tales.</p>\n\n<p>In Tolkien's narrative conceit, in which all the writings of Middle-earth are\n'really' translations from the fictitious volume of The Red Book of Westmarch,\nBilbo is the author of The Hobbit and translator of The Silmarillion.</p>\n\n<p>From <a href=\"http://en.wikipedia.org/wiki/Bilbo_Baggins\">http://en.wikipedia.org/wiki/Bilbo_Baggins</a>.</p>"
    actual   = page.formatted_data
    assert_html_equal expected, actual

    assert_equal 'Hobbit.md', page.path
    assert_equal :markdown, page.format
  end
end

context "within a sub-directory" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"), { :page_file_dir => 'Rivendell' })
  end

  test "get existing page" do
    page = @wiki.page('Elrond')
    assert_equal Gollum::Page, page.class
    assert page.raw_data =~ /^# Elrond\n\nElrond/
    assert_equal 'Rivendell/Elrond.md', page.path
    assert_equal :markdown, page.format
    assert_equal @wiki.repo.commits.first.id, page.version.id
  end

  test "should not get page from parent dir" do
    page = @wiki.page('Bilbo-Baggins')
    assert_equal nil, page
  end

  test "should inherit header/footer/sidebar pages from parent directories" do
    page = @wiki.page('Elrond')

    assert_equal Gollum::Page, page.sidebar.class
    assert_equal Gollum::Page, page.header.class
    assert_equal Gollum::Page, page.footer.class

    assert page.sidebar.raw_data =~ /^Lord of the Rings/
    assert page.header.raw_data =~ /^Hobbits/
    assert page.footer.raw_data =~ /^Lord of the Rings/
  end

  test "get metadata on page" do
    page = @wiki.page('Elrond')
    assert_equal Gollum::Page, page.class
    assert_equal 'elf', page.metadata['race']
  end

end

context "with custom markup engines" do
  setup do
    Gollum::Markup.register(:redacted, "Redacted", :extensions => ['rd']) { |content| content.gsub(/\S/, '-') }
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "should use the specified engine" do
    page = @wiki.page('Riddles')
    assert_equal :redacted, page.format
    assert page.raw_data.include? 'Time'
    assert page.raw_data =~ /^[\s\-]*$/
  end
end
