# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Wiki initialize" do
  test "post_wiki_initialize hooks called after initializing" do
    yielded = nil
    begin
      Gollum::Hook.register(:post_wiki_initialize, :hook) do |wiki|
        yielded = wiki
      end

      assert_equal Gollum::Wiki.new(testpath("examples/lotr.git")), yielded
    ensure
      Gollum::Hook.unregister(:post_wiki_initialize, :hook)
    end
  end
end

context "Wiki" do
  setup do
    @wiki                       = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "repo path" do
    assert_equal testpath("examples/lotr.git"), @wiki.path
  end

  test "git repo" do
    assert_equal Gollum::Git::Repo, @wiki.repo.class
    assert @wiki.exist?
  end

  test "shows paginated log with no page" do
    Gollum::Wiki.per_page = 3
    commits               = @wiki.repo.commits[0..2].map(&:id)
    assert_equal commits, @wiki.log.map { |c| c.id }
  end

  test "shows paginated log with 1st page" do
    Gollum::Wiki.per_page = 3
    commits               = @wiki.repo.commits[0..2].map(&:id)
    assert_equal commits, @wiki.log(:page_num => 1).map(&:id)
  end

  test "shows paginated log with next page" do
    Gollum::Wiki.per_page = 3
    commits               = @wiki.repo.commits[3..5].map(&:id)
    assert_equal commits, @wiki.log(:page_num => 2).map(&:id)
  end

  test "list files and pages" do
    contents = @wiki.tree_list
    pages = contents.select {|x| x.is_a?(::Gollum::Page)}
    assert_equal \
      ['Bilbo-Baggins.md', 'Boromir.md', 'Elrond.md', 'Eye-Of-Sauron.md', 'Hobbit.md', 'Home.textile', 'My-Precious.md', 'RingBearers.md', 'Samwise Gamgee.mediawiki', 'todo.txt'],
      pages.map(&:filename).sort
    files = contents.select {|x| x.class.to_s == 'Gollum::File'}
    assert_equal \
      ['Data-Two.csv', 'Data.csv', 'Riddles.rd', 'eye.jpg'],
      files.map(&:filename).sort
  end

  test "list pages" do
    pages = @wiki.pages
    assert_equal \
      ['Bilbo-Baggins.md', 'Boromir.md', 'Elrond.md', 'Eye-Of-Sauron.md', 'Hobbit.md', 'Home.textile', 'My-Precious.md', 'RingBearers.md', 'Samwise Gamgee.mediawiki', 'todo.txt'],
      pages.map(&:filename).sort
  end

  test "list files" do
    files = @wiki.files
    assert_equal \
      ['Data-Two.csv', 'Data.csv', 'Riddles.rd', 'eye.jpg'],
      files.map(&:filename).sort
  end

  test "counts pages" do
    assert_equal 10, @wiki.size
  end

  test "latest changes in repo" do
    assert_equal @wiki.latest_changes({:max_count => 1}).first.id, "324396c422678622ca16524424161429ee673bb9"
  end

  test "text_data" do
    wiki = Gollum::Wiki.new(testpath("examples/yubiwa.git"))
    if String.instance_methods.include?(:encoding)
      utf8 = wiki.page("strider").text_data
      assert_equal Encoding::UTF_8, utf8.encoding
      sjis = wiki.page("sjis").text_data(Encoding::SHIFT_JIS)
      assert_equal Encoding::SHIFT_JIS, sjis.encoding
    else
      page = wiki.page("strider")
      assert_equal page.raw_data, page.text_data
    end
  end

  test "gets scoped page from specified directory" do
    @path = cloned_testpath('examples/lotr.git')
    begin
      wiki  = Gollum::Wiki.new(@path)
      index = wiki.repo.index
      index.read_tree 'master'
      index.add('Foobar/Elrond.md', 'Baz')
      index.commit 'Add Foobar/Elrond.', [wiki.repo.head.commit], Gollum::Git::Actor.new('Tom Preston-Werner', 'tom@github.com')

      assert_equal 'Rivendell/Elrond.md', wiki.page('Rivendell/Elrond').path
      # test paged as well.
      assert_equal 'Foobar/Elrond.md', wiki.page('Foobar/Elrond').path
    ensure
      FileUtils.rm_rf(@path)
    end
  end
end

context "Wiki page previewing" do
  setup do
    @path                        = testpath("examples/lotr.git")
    Gollum::Wiki.default_options = { :universal_toc => false }
    @wiki                        = Gollum::Wiki.new(@path)
  end

  test "preview_page" do
    page = @wiki.preview_page("Test", "# Bilbo", :markdown)
    assert_equal "# Bilbo", page.raw_data
    assert_html_equal "<h1 class=\"editable\"><a class=\"anchor\" id=\"bilbo\" href=\"#bilbo\"></a>Bilbo</h1>", page.formatted_data
    assert_equal "Test.md", page.filename
    assert_equal "Test", page.name

    # Getting and setting subpage contents
    assert page.set_sidebar("*Hobbit*\n")
    assert_html_equal page.sidebar.formatted_data, "<p><em>Hobbit</em></p>\n"

    # Sidebar uses TOC data from parent page.
    assert page.set_sidebar('[[_TOC_]]')
    assert_html_equal page.sidebar.formatted_data, "<p><div class=\"toc\"><div class=\"toc-title\">Table of Contents</div><ul><li><a href=\"#bilbo\">Bilbo</a></li></ul></div></p>"

    assert_equal @wiki.repo.commit(@wiki.ref).id, page.version.id
    assert_nil page.last_version
    assert page.versions.empty?
  end

  test 'preview page updates its path' do
    page = @wiki.preview_page("Test", "# Bilbo", :markdown)
    assert_equal "Test.md", page.escaped_url_path
    page.path = "Renamed.md"
    assert_equal "Renamed.md", page.escaped_url_path
  end 
end

context "Wiki TOC" do
  setup do
    @path   = testpath("examples/lotr.git")
    options = { :universal_toc => true }
    @wiki   = Gollum::Wiki.new(@path, options)
  end

  test "empty TOC" do
    page = @wiki.preview_page("Test", "[[_TOC_]] [[_TOC_|levels = 2]] Bilbo", :markdown)
    assert_html_equal "<p>Bilbo</p>", page.formatted_data
    assert_empty page.toc_data
  end

  test "toc_generation" do
    page = @wiki.preview_page("Test", "# Bilbo", :markdown)
    assert_equal "# Bilbo", page.raw_data
    assert_html_equal "<h1 class=\"editable\"><a class=\"anchor\" id=\"bilbo\" href=\"#bilbo\"></a>Bilbo</h1>", page.formatted_data
    assert_html_equal %{<div class="toc"><div class="toc-title">Table of Contents</div><ul><li><a href="#bilbo">Bilbo</a></li></ul></div>}, page.toc_data
  end

  test "TOC with levels" do
    content = <<-MARKDOWN
# Ecthelion

## Denethor

### Ecthelion

### Boromir

### Faramir
    MARKDOWN

    formatted = <<-HTML
<h1 class=\"editable\"><a class="anchor" id="ecthelion" href="#ecthelion"></a>Ecthelion</h1>
<h2 class=\"editable\"><a class="anchor" id="denethor" href="#denethor"></a>Denethor</h2>
<h3 class=\"editable\"><a class="anchor" id="ecthelion-1" href="#ecthelion-1"></a>Ecthelion</h3>
<h3 class=\"editable\"><a class="anchor" id="boromir" href="#boromir"></a>Boromir</h3>
<h3 class=\"editable\"><a class="anchor" id="faramir" href="#faramir"></a>Faramir</h3>
    HTML

    page_level0 = @wiki.preview_page("Test", "[[_TOC_ | levels=0]] \n\n" + content, :markdown)
    toc_formatted_level0 = <<-HTML
<p><div class="toc"><div class="toc-title">Table of Contents</div></div></p>
    HTML
    assert_html_equal toc_formatted_level0 + formatted, page_level0.formatted_data

    page_level1 = @wiki.preview_page("Test", "[[_TOC_ | levels=1]] \n\n" + content, :markdown)
    toc_formatted_level1 = <<-HTML
<p><div class="toc">
<div class="toc-title">Table of Contents</div>
<ul><li><a href="#ecthelion">Ecthelion</a></li></ul>
</div></p>
    HTML
    assert_html_equal toc_formatted_level1 + formatted, page_level1.formatted_data

    page_level2 = @wiki.preview_page("Test", "[[_TOC_ |levels = 2]] \n\n" + content, :markdown)
    toc_formatted_level2 = <<-HTML
<p><div class="toc">
<div class="toc-title">Table of Contents</div>
<ul><li><a href="#ecthelion">Ecthelion</a>
<ul><li><a href="#denethor">Denethor</a></li></ul>
</li></ul>
</div></p>
    HTML
    assert_html_equal toc_formatted_level2 + formatted, page_level2.formatted_data

    page_level3 = @wiki.preview_page("Test", "[[_TOC_ |levels = 3]] \n\n" + content, :markdown)
    page_level4 = @wiki.preview_page("Test", "[[_TOC_ |levels = 4]] \n\n" + content, :markdown)
    page_fulltoc = @wiki.preview_page("Test", "[[_TOC_]] \n\n" + content, :markdown)
    toc_formatted_full = <<-HTML
<p><div class="toc">
<div class="toc-title">Table of Contents</div>
<ul>
  <li>
    <a href="#ecthelion">Ecthelion</a>
    <ul>
      <li><a href="#denethor">Denethor</a>
    <ul>
      <li><a href="#ecthelion-1">Ecthelion</a></li>
      <li><a href="#boromir">Boromir</a></li>
      <li><a href="#faramir">Faramir</a></li>
    </ul>
  </li></ul>
</li></ul>
</div></p>
    HTML
    assert_html_equal toc_formatted_full + formatted, page_level3.formatted_data
    assert_html_equal toc_formatted_full + formatted, page_level3.formatted_data
    assert_html_equal toc_formatted_full + formatted, page_fulltoc.formatted_data

  end

  # Ensure ' creates valid links in TOC
  # Incorrect: <a href=\"#a\" b=\"\">
  #   Correct: <a href=\"#a'b\">
  test "' in link" do
    page = @wiki.preview_page("Test", "# a'b", :markdown)
    assert_equal "# a'b", page.raw_data
    assert_html_equal "<h1 class=\"editable\"><a class=\"anchor\" id=\"a-b\" href=\"#a-b\"></a>a'b</h1>", page.formatted_data
    assert_html_equal %{<div class=\"toc\"><div class=\"toc-title\">Table of Contents</div><ul><li><a href=\"#a-b\">a'b</a></li></ul></div>}, page.toc_data
  end
end

context "Wiki TOC in _Sidebar.md" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    Gollum::Git::Repo.init_bare(@path)
    options = { :universal_toc => true }
    @wiki = Class.new(Gollum::Wiki).new(@path, options)
  end

  test "_Sidebar.md with [[_TOC_]] renders TOC" do
    cd = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", cd)
    page = @wiki.page("Gollum")
    @wiki.write_page("_Sidebar", :markdown, "[[_TOC_]]", cd)
    sidebar = page.sidebar
    assert_not_equal '', sidebar.toc_data
    assert_html_equal "<p><div class=\"toc\"><div class=\"toc-title\">Table of Contents</div><ul><li><a href=\"#gollum\">Gollum</a></li></ul></div></p>\n", sidebar.formatted_data
  end

  teardown do
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), *%w(examples test.git)))
  end
end

context "Wiki page writing" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    Gollum::Git::Repo.init_bare(@path)
    @wiki = Gollum::Wiki.new(@path)
  end

  test "write_page" do
    cd = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", cd)
    assert_equal 1, @wiki.repo.commits.size
    assert_equal cd[:message], @wiki.repo.commits.first.message
    assert_equal cd[:name], @wiki.repo.commits.first.author.name
    assert_equal cd[:email], @wiki.repo.commits.first.author.email

    cd2 = { :message => "Updating Bilbo", :author => "Samwise" }
    @wiki.write_page("Bilbo", :markdown, "# Bilbo", cd2)

    commits      = @wiki.repo.commits
    # FIXME Grit commits ordering is not predictable. See #13.
    # The following line should be: commit = commits.first
    first_commit = commits.find { |c| c.message == "Updating Bilbo" }

    assert_equal 2, commits.size
    assert_equal cd2[:message], first_commit.message
    assert_equal cd2[:name], first_commit.author.name
    assert_equal cd2[:email], first_commit.author.email
    assert @wiki.page("Bilbo")
    assert @wiki.page("Gollum")

    @wiki.write_page("//Saruman", :markdown, "# Saruman", cd2)
    assert @wiki.page("Saruman")
  end

  test "write page is not allowed to overwrite pages" do
    @wiki.write_page("Abc-Def", :markdown, "# Gollum", commit_details)
    assert_raises Gollum::DuplicatePageError do
      @wiki.write_page("Abc-Def", :markdown, "# Gollum", commit_details)
    end
    @wiki.write_page("subdir/Abc-Def", :markdown, "# Gollum", commit_details)
    assert_raises Gollum::DuplicatePageError do
      @wiki.write_page("subdir/Abc-Def", :markdown, "# Gollum", commit_details)
    end
    assert_nothing_raised Gollum::DuplicatePageError do
      @wiki.write_page("Abc-Def", :textile, "# Gollum", commit_details)
    end
    assert_nothing_raised Gollum::DuplicatePageError do
      @wiki.write_page("abc-def", :markdown, "# Gollum", commit_details)
    end
  end
  
  test "write file is not allowed to overwrite files" do
    @wiki.write_file("Abc-Def.file", "# Gollum", commit_details)
    assert_raises Gollum::DuplicatePageError do
      @wiki.write_file("Abc-Def.file", "# Gollum", commit_details)
    end
    @wiki.write_file("subdir/Abc-Def.file", "# Gollum", commit_details)
    assert_raises Gollum::DuplicatePageError do
      @wiki.write_file("subdir/Abc-Def.file", "# Gollum", commit_details)
    end
  end

  test "overwrite file is allowed to overwrite an existing file" do
    @wiki.write_file("Abc-Def.file", "# Gollum", commit_details)
    assert_nothing_raised Gollum::DuplicatePageError do
      @wiki.overwrite_file("Abc-Def.file", "# Gollum modified", commit_details)
    end
    assert_equal "# Gollum modified", @wiki.file("Abc-Def.file").raw_data
  end

  test "write_page does not mutate input parameters" do
    name = "Hello There"
    @wiki.write_page(name, :markdown, 'content', commit_details)
    assert_equal name, "Hello There"
  end

  test "update_page" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    page = @wiki.page("Gollum")
    @wiki.update_page(page, page.name, :markdown, "# Smeagol", {
        :message => "Leave now, and never come back!",
        :name    => "Smeagol",
        :email   => "smeagol@example.org"
    })

    commits      = @wiki.repo.commits
    # FIXME Grit commits ordering is not predictable. See #13.
    # The following line should be: first_commit = commits.first
    first_commit = commits.find { |c| c.author.name == "Smeagol" }

    assert_equal 2, commits.size
    assert_equal "# Smeagol", @wiki.page("Gollum").raw_data
    assert_equal "Leave now, and never come back!", first_commit.message
    assert_equal "Smeagol", first_commit.author.name
    assert_equal "smeagol@example.org", first_commit.author.email
  end

  test "update page is not allowed to overwrite file with name change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    @wiki.write_page("Smeagel", :markdown, "# Smeagel", commit_details)
    page = @wiki.page("Gollum")
    assert_raises Gollum::DuplicatePageError do
      @wiki.update_page(page, 'Smeagel', :markdown, "h1. Gollum", commit_details)
    end
  end

  test "page title override with metadata" do
    @wiki.write_page("Gollum", :markdown, "---\ntitle: Over\n...", commit_details)

    page = @wiki.page("Gollum")

    assert_equal 'Over', page.url_path_title
  end

  test "update page with format change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, page.name, :textile, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal :textile, @wiki.page("Gollum").format
    assert_equal "h1. Gollum", @wiki.page("Gollum").raw_data
  end

  test "update page with name change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Smeagol', :markdown, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal "h1. Gollum", @wiki.page("Smeagol").raw_data
  end

  test "update page with name and format change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Smeagol', :textile, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal :textile, @wiki.page("Smeagol").format
    assert_equal "h1. Gollum", @wiki.page("Smeagol").raw_data
  end

  test "update nested page with format change" do
    index = @wiki.repo.index
    index.add("lotr/Gollum.md", "# Gollum")
    index.commit("Add nested page")

    page = @wiki.page("lotr/Gollum")
    assert_equal :markdown, @wiki.page("lotr/Gollum").format
    @wiki.update_page(page, page.name, :textile, "h1. Gollum", commit_details)

    page = @wiki.page("lotr/Gollum")
    assert_equal "lotr/Gollum.textile", page.path
    assert_equal :textile, page.format
    assert_equal "h1. Gollum", page.raw_data
  end

  test "delete root page" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    page = @wiki.page("Gollum")
    @wiki.delete_page(page, commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_nil @wiki.page("Gollum")
  end

  test "delete nested page" do
    index = @wiki.repo.index
    index.add("greek/Bilbo-Baggins.md", "hi")
    index.add("Gollum.md", "hi")
    index.commit("Add alpha.jpg")

    page = @wiki.page("greek/Bilbo-Baggins")
    assert page
    @wiki.delete_page(page, commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_nil @wiki.page("greek/Bilbo-Baggins")

    assert @wiki.page("Gollum")
  end

  teardown do
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), *%w(examples test.git)))
  end
end

context "Wiki page writing with whitespace (filename honors whitespace)" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  test "update_page" do
    assert_equal :mediawiki, @wiki.page("Samwise Gamgee").format
    assert_equal "Samwise Gamgee.mediawiki", @wiki.page("Samwise Gamgee").filename

    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, page.name, :textile, "h1. Samwise Gamgee2", commit_details)

    assert_equal :textile, @wiki.page("Samwise Gamgee").format
    assert_equal "h1. Samwise Gamgee2", @wiki.page("Samwise Gamgee").raw_data
    assert_equal "Samwise Gamgee.textile", @wiki.page("Samwise Gamgee").filename
  end

  test "update page with format change, verify non-canonicalization of filename,  where filename contains Whitespace" do
    assert_equal :mediawiki, @wiki.page("Samwise Gamgee").format
    assert_equal "Samwise Gamgee.mediawiki", @wiki.page("Samwise Gamgee").filename

    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, page.name, :textile, "h1. Samwise Gamgee", commit_details)

    assert_equal :textile, @wiki.page("Samwise Gamgee").format
    assert_equal "h1. Samwise Gamgee", @wiki.page("Samwise Gamgee").raw_data
    assert_equal "Samwise Gamgee.textile", @wiki.page("Samwise Gamgee").filename
  end

  test "update page with name change, verify canonicalization of filename, where filename contains Whitespace" do
    assert_equal :mediawiki, @wiki.page("Samwise Gamgee").format
    assert_equal "Samwise Gamgee.mediawiki", @wiki.page("Samwise Gamgee").filename

    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, 'Sam Gamgee', :textile, "h1. Samwise Gamgee", commit_details)

    assert_equal "h1. Samwise Gamgee", @wiki.page("Sam Gamgee").raw_data
    assert_equal "Sam Gamgee.textile", @wiki.page("Sam Gamgee").filename
  end

  test "update page with name and format change, verify canonicalization of filename, where filename contains Whitespace" do
    assert_equal :mediawiki, @wiki.page("Samwise Gamgee").format
    assert_equal "Samwise Gamgee.mediawiki", @wiki.page("Samwise Gamgee").filename

    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, 'Sam Gamgee', :textile, "h1. Samwise Gamgee", commit_details)

    assert_equal :textile, @wiki.page("Sam Gamgee").format
    assert_equal "h1. Samwise Gamgee", @wiki.page("Sam Gamgee").raw_data
    assert_equal "Sam Gamgee.textile", @wiki.page("Sam Gamgee").filename
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end

context "Wiki sync with working directory" do
  setup do
    @path = testpath('examples/wdtest')
    Gollum::Git::Repo.init(@path)
    @wiki = Gollum::Wiki.new(@path)
  end

  test "write a page" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    assert_equal "Hi", File.read(File.join(@path, "New Page.md"))
  end

  test "write a page in subdirectory" do
    @wiki.write_page("Subdirectory/New Page", :markdown, "Hi", commit_details)
    assert_equal "Hi", File.read(File.join(@path, "Subdirectory", "New Page.md"))
  end

  test "update a page with same name and format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, page.name, page.format, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New Page.md"))
  end

  test "update a page with different name and same format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, "New Page 2", page.format, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New Page 2.md"))
    assert !File.exist?(File.join(@path, "New Page.md"))
  end

  test "update a page with same name and different format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, page.name, :textile, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New Page.textile"))
    assert !File.exist?(File.join(@path, "New Page.md"))
  end

  test "update a page with different name and different format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, "New Page 2", :textile, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New Page 2.textile"))
    assert !File.exist?(File.join(@path, "New Page.md"))
  end

  test "delete a page" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.delete_page(page, commit_details)
    assert !File.exist?(File.join(@path, "New Page.md"))
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end

context "Wiki sync with working directory (filename contains whitespace)" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end
  test "update a page with same name and format" do
    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, page.name, page.format, "What we need is a few good taters.", commit_details)
    assert_equal "What we need is a few good taters.", File.read(File.join(@path, "Samwise Gamgee.mediawiki"))
  end

  test "update a page with different name and same format" do
    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, "Sam Gamgee", page.format, "What we need is a few good taters.", commit_details)
    assert_equal "What we need is a few good taters.", File.read(File.join(@path, "Sam Gamgee.mediawiki"))
    assert !File.exist?(File.join(@path, "Samwise Gamgee"))
  end

  test "update a page with same name and different format" do
    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, page.name, :textile, "What we need is a few good taters.", commit_details)
    assert_equal "What we need is a few good taters.", File.read(File.join(@path, "Samwise Gamgee.textile"))
    assert !File.exist?(File.join(@path, "Samwise Gamgee.mediawiki"))
  end

  test "update a page with different name and different format" do
    page = @wiki.page("Samwise Gamgee")
    @wiki.update_page(page, "Sam Gamgee", :textile, "What we need is a few good taters.", commit_details)
    assert_equal "What we need is a few good taters.", File.read(File.join(@path, "Sam Gamgee.textile"))
    assert !File.exist?(File.join(@path, "Samwise Gamgee.mediawiki"))
  end

  test "delete a page" do
    page = @wiki.page("Samwise Gamgee")
    @wiki.delete_page(page, commit_details)
    assert !File.exist?(File.join(@path, "Samwise Gamgee.mediawiki"))
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end

context "page_file_dir option" do
  setup do
    @path          = cloned_testpath('examples/page_file_dir')
    @page_file_dir = 'docs'
    @wiki          = Gollum::Wiki.new(@path, :page_file_dir => @page_file_dir)
  end

  test "write a page in sub directory" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    assert_equal "Hi", File.read(File.join(@path, @page_file_dir, "New Page.md"))
    assert !File.exist?(File.join(@path, "New Page.md"))
  end

  test "edit a page in a sub directory" do
    page = @wiki.page('foo')
    @wiki.update_page(page, page.name, page.format, 'new contents', commit_details)
  end

  test 'delete a page' do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    result = @wiki.page("New Page")
    assert_not_nil result
    @wiki.delete_page(result, commit_details)
    assert_nil @wiki.page("New Page")
  end

  test "a file in page file dir should be found" do
    assert @wiki.page("foo")
  end

  test "a file in page file dir should have the correct url path" do
    assert_equal 'docs/foo.md', @wiki.page("foo").path
    assert_equal 'foo.md', @wiki.page("/foo").url_path
    @wiki.write_page("baz/Test", :markdown, "Hi", commit_details)
    assert_equal 'baz/Test.md', @wiki.page('baz/Test').url_path
  end

  test "a file out of page file dir should not be found" do
    assert !@wiki.page("bar")
  end

  test "can't write files in root" do
    assert_raises Gollum::IllegalDirectoryPath do
      @wiki.write_page("../Malicious", :markdown, "Hi", {})
    end
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end

context "Wiki page writing with different branch" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    @repo = Gollum::Git::Repo.init_bare(@path)
    @wiki = Gollum::Wiki.new(@path)

    # We need an initial commit to create the master branch
    # before we can create new branches
    cd    = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", cd)

    # Create our test branch and check it out
    @repo.update_ref("test", @repo.commits.first.id)
    @branch = Gollum::Wiki.new(@path, :ref => "test")
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "write_page" do
    @branch.write_page("Bilbo", :markdown, "# Bilbo", commit_details)
    assert @branch.page("Bilbo")
    assert @wiki.page("Gollum")

    assert_equal 1, @wiki.repo.commits.size
    assert_equal 1, @branch.repo.commits.size

    assert_equal nil, @wiki.page("Bilbo")
  end
end

context "redirects" do

  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  test "#redirects returns an empty hash if the .redirects.gollum file does not exist" do
    assert @wiki.redirects.empty?
  end
  
  test "#redirects returns a hash with redirects if the .redirects.gollum file exists" do
    @wiki.write_file('.redirects.gollum', {'Home.old.md' => 'Home.md'}.to_yaml)
    assert_equal 'Home.md', @wiki.redirects['Home.old.md']
  end
  
  test "#add_redirect modifies the .redirects.gollum file by adding a redirect entry" do
    @wiki.add_redirect('oldpage.md', 'newpage.md')
    redirects_file = @wiki.file('.redirects.gollum')
    assert_equal "---\noldpage.md: newpage.md\n", redirects_file.raw_data
  end
  
  test "#remove_redirect modifies the .redirects.gollum file by removing a redirect entry" do
    @wiki.add_redirect('oldpage.md', 'newpage.md')
    @wiki.remove_redirect('oldpage.md')
    redirects_file = @wiki.file('.redirects.gollum')
    assert_equal "--- {}\n", redirects_file.raw_data
  end

  test "#redirects reloads the redirects hash when the cache has become stale" do
    @wiki.add_redirect('oldpage.md', 'newpage.md')
    redirects = @wiki.redirects
    object_id1 = redirects.object_id
    assert_equal 'newpage.md', redirects['oldpage.md']
    # Test that the cache works by calling #redirects again
    assert_equal object_id1, @wiki.redirects.object_id
    # Overwriting the redirects file changes HEAD, turning the redirects cache stale
    @wiki.overwrite_file('.redirects.gollum', {'Home.old.md' => 'Home.md'}.to_yaml)
    redirects = @wiki.redirects
    object_id2 = redirects.object_id
    assert_not_equal object_id1, object_id2
    assert_equal nil, redirects['oldpage.md']
    assert_equal 'Home.md', redirects['Home.old.md']
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
  
end

context "Renames directory traversal" do
  setup do
    @path = cloned_testpath("examples/revert.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "rename aborts on nil" do
    res = @wiki.rename_page(@wiki.page("some-super-fake-page"), "B", rename_commit_details)
    assert !res, "rename did not abort with non-existant page"
    res = @wiki.rename_page(@wiki.page("B"), "", rename_commit_details)
    assert !res, "rename did not abort with empty rename"
    res = @wiki.rename_page(@wiki.page("B"), nil, rename_commit_details)
    assert !res, "rename did not abort with nil rename"
  end

  test "rename page no-act" do
    # Make sure renames don't do anything if the name is the same.
    # B.md => B.md
    res = @wiki.rename_page(@wiki.page("B"), "B", rename_commit_details)
    assert !res, "NOOP rename did not abort"
  end

  test "rename page without directories" do
    # Make sure renames work with relative paths.
    source = @wiki.page("B")

    # B.md => C.md
    assert @wiki.rename_page(source, "C", rename_commit_details)

    assert_renamed source, @wiki.page("C")
  end

  test "rename page containing space without directories" do
    # Make sure renames involving spaces work with relative paths.
    source = @wiki.page("B")

    # B.md => C D.md
    assert @wiki.rename_page(source, "C D", rename_commit_details)

    assert_renamed source, @wiki.page("C D")
  end

  test "rename page with subdirs" do
    # Make sure renames in subdirectories happen ok
    source = @wiki.page("G/H")

    # G/H.md => G/F.md
    assert @wiki.rename_page(source, "G/F", rename_commit_details)

    assert_renamed source, @wiki.page("G/F")
  end

  test "rename page containing space with subdir" do
    # Make sure renames involving spaces in subdirectories happen ok
    source = @wiki.page("G/H")

    # G/H.md => G/F H.md
    assert @wiki.rename_page(source, "G/F H", rename_commit_details)

    assert_renamed source, @wiki.page("G/F H")
  end

  test "rename page absolute path is still no-act" do
    # Make sure renames don't do anything if the name is the same.

    # B.md => B.md
    res = @wiki.rename_page(@wiki.page("B"), "/B", rename_commit_details)
    assert !res, "NOOP rename did not abort"
  end

  test "rename page absolute path NOOPs ok" do
    # Make sure renames don't do anything if the name is the same and we are in a subdirectory.
    source = @wiki.page("G/H")

    # G/H.md => G/H.md
    res    = @wiki.rename_page(source, "/G/H", rename_commit_details)
    assert !res, "NOOP rename did not abort"
  end

  test "rename page absolute directory" do
    # Make sure renames work with absolute paths.
    source = @wiki.page("B")

    # B.md => C.md
    assert @wiki.rename_page(source, "/C", rename_commit_details)

    assert_renamed source, @wiki.page("C")
  end

  test "rename page with space absolute directory" do
    # Make sure renames involving spaces work with absolute paths.
    source = @wiki.page("B")

    # B.md => C D.md
    assert @wiki.rename_page(source, "/C D", rename_commit_details)

    assert_renamed source, @wiki.page("C D")
  end

  test "rename page absolute directory with subdirs" do
    # Make sure renames in subdirectories happen ok
    source = @wiki.page("G/H")

    # G/H.md => G/F.md
    assert @wiki.rename_page(source, "/G/F", rename_commit_details)

    assert_renamed source, @wiki.page("G/F")
  end

  test "rename page containing space absolute directory with subdir" do
    # Make sure renames involving spaces in subdirectories happen ok
    source = @wiki.page("G/H")

    # G/H.md => G/F H.md
    assert @wiki.rename_page(source, "/G/F H", rename_commit_details)

    assert_renamed source, @wiki.page("G/F H")
  end

  test "rename page relative directory with new dir creation" do
    # Make sure renames in subdirectories create more subdirectories ok
    source = @wiki.page("G/H")

    # G/H.md => G/K/F.md
    assert @wiki.rename_page(source, "K/F", rename_commit_details)

    new_page = @wiki.page("K/F")
    assert_not_nil new_page
    assert_renamed source, new_page
  end

  test "rename page relative directory with new dir creation containing space" do
    # Make sure renames involving spaces in subdirectories create more subdirectories ok
    source = @wiki.page("G/H")

    # G/H.md => G/K L/F.md
    assert @wiki.rename_page(source, "K L/F", rename_commit_details)

    new_page = @wiki.page("K L/F")
    assert_not_nil new_page
    assert_renamed source, new_page
  end

  test "rename page absolute directory with subdir creation" do
    # Make sure renames in subdirectories create more subdirectories ok
    source = @wiki.page("G/H")

    # G/H.md => G/K/F.md
    assert @wiki.rename_page(source, "/G/K/F", rename_commit_details)

    new_page = @wiki.page("G/K/F")
    assert_not_nil new_page
    assert_renamed source, new_page
  end

  test "rename page absolute directory with subdir creation containing space" do
    # Make sure renames involving spaces in subdirectories create more subdirectories ok
    source = @wiki.page("G/H")

    # G/H.md => G/K L/F.md
    assert @wiki.rename_page(source, "/G/K L/F", rename_commit_details)

    new_page = @wiki.page("G/K L/F")
    assert_not_nil new_page
    assert_renamed source, new_page
  end

  test "rename page with a name of an already existing page does not clobber that page" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    @wiki.write_page("Smeagel", :markdown, "# Smeagel", commit_details)
    page = @wiki.page("Gollum")
    assert_raises Gollum::DuplicatePageError do
      @wiki.rename_page(page, 'Smeagel', rename_commit_details)
    end
  end

  def assert_renamed(page_source, page_target)
    @wiki.clear_cache
    assert_nil @wiki.page(::File.join(page_source.path, page_source.name))

    assert_equal "INITIAL\n\nSPAM2\n", page_target.raw_data
    assert_equal "def", page_target.version.message
    assert_equal "Smeagol", page_target.version.author.name
    assert_equal "smeagol@example.org", page_target.version.author.email
    assert_not_equal page_source.version.sha, page_target.version.sha
  end

  def rename_commit_details
    { :message => "def", :name => "Smeagol", :email => "smeagol@example.org" }
  end
end

context "Wiki subclassing" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    Gollum::Git::Repo.init_bare(@path)
    @wiki = Class.new(Gollum::Wiki).new(@path)
  end

  test "wiki page can be written by subclass" do
    details = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", details)
    page = @wiki.page("Gollum")
    first_commit = @wiki.repo.commits.first

    assert_equal 1, @wiki.repo.commits.size
    assert_equal details[:name], first_commit.author.name
    assert_equal details[:email], first_commit.author.email
    assert_equal details[:message], first_commit.message
    assert_equal "# Gollum", page.raw_data
  end

  test "wiki page can be updated by subclass" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    page = @wiki.page("Gollum")

    @wiki.update_page(page, page.name, :markdown, "# Smeagol", {
        :name    => "Smeagol",
        :email   => "smeagol@example.org",
        :message => "Leave now, and never come back!"
    })
    page = @wiki.page("Gollum")
    first_commit = @wiki.repo.commits.find { |c| c.author.name == "Smeagol" }

    assert_equal 2, @wiki.repo.commits.size
    assert_equal "Smeagol", first_commit.author.name
    assert_equal "smeagol@example.org", first_commit.author.email
    assert_equal "Leave now, and never come back!", first_commit.message
    assert_equal "# Smeagol", page.raw_data
  end

  test "wiki page can be deleted by subclass" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    page = @wiki.page("Gollum")

    @wiki.delete_page(page, commit_details)
    page = @wiki.page("Gollum")

    assert_equal 2, @wiki.repo.commits.size
    assert_nil page
  end

  teardown do
    FileUtils.rm_rf(File.join(File.dirname(__FILE__), *%w(examples test.git)))
  end
end
