# ~*~ encoding: utf-8 ~*~
require File.expand_path("../helper", __FILE__)
require File.expand_path("../wiki_factory", __FILE__)

context "Markup" do
  setup do
    @wiki, @path, @teardown = WikiFactory.create 'examples/test.git'
  end

  teardown do
    @teardown.call
  end

  test "formats page from Wiki#pages" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Foo]][[Bar]] b", commit_details)
    assert @wiki.pages[0].formatted_data
  end

  # This test is to assume that Sanitize.clean doesn't raise Encoding::CompatibilityError on ruby 1.9
  test "formats non ASCII-7 character page from Wiki#pages" do
    wiki = Gollum::Wiki.new(testpath("examples/yubiwa.git"))
    assert_nothing_raised(defined?(Encoding) && Encoding::CompatibilityError) do
      assert wiki.page("strider").formatted_data
    end
  end

  test "Gollum::Markup#render yields a DocumentFragment" do
    yielded = false
    @wiki.write_page("Yielded", :markdown, "abc", commit_details)

    page   = @wiki.page("Yielded")
    markup = Gollum::Markup.new(page)
    markup.render do |doc|
      assert_kind_of Nokogiri::HTML::DocumentFragment, doc
      yielded = true
    end
    assert yielded
  end

  test "Gollum::Page#formatted_data yields a DocumentFragment" do
    yielded = false
    @wiki.write_page("Yielded", :markdown, "abc", commit_details)

    page = @wiki.page("Yielded")
    page.formatted_data do |doc|
      assert_kind_of Nokogiri::HTML::DocumentFragment, doc
      yielded = true
    end
    assert yielded, "Gollum::Page#formatted_data should yield a document"

    yielded = false
    page.formatted_data do
      yielded = true
    end
    assert yielded, "Gollum::Page#formatted_data should yield a document even when formatted_data is taken from cache"
  end

  test "Gollum::Markup#formats returns all formats by default" do
    assert Gollum::Markup.formats.keys.include?(:asciidoc)
    assert Gollum::Markup.formats.size > 1
  end

  test "knows whether to skip specified filters" do
      Gollum::Markup.stubs(:formats).returns({:markdown => {:skip_filters => [:Render], :extensions => ['md']}})
      @wiki.write_page("Test", :markdown, "abc", commit_details)
      page   = @wiki.page("Test")
      markup = Gollum::Markup.new(page)
      assert_equal false, markup.skip_filter?(:YAML)
      assert_equal true, markup.skip_filter?(:Render)

      Gollum::Markup.stubs(:formats).returns({:markdown => {:skip_filters => Proc.new {|x| x == :Render}, :extensions => ['md']}})
      assert_equal false, markup.skip_filter?(:YAML)
      assert_equal true, markup.skip_filter?(:Render)
  end

  test "knows whether link parts for this markup are reversed" do
    Gollum::Markup.stubs(:formats).returns({:markdown => {:reverse_links => true, :extensions => ['md']}})
    @wiki.write_page("Test", :markdown, "abc", commit_details)
    page   = @wiki.page("Test")
    markup = Gollum::Markup.new(page)
    assert_equal true, markup.reverse_links?
  end

  test "Gollum::Markup#formats is limited by Gollum::Page::FORMAT_NAMES" do
    begin
      Gollum::Page::FORMAT_NAMES = { :markdown => "Markdown" }
      assert Gollum::Markup.formats.keys.include?(:markdown)
      assert !Gollum::Markup.formats.keys.include?(:asciidoc)
    ensure
      Gollum::Page.send :remove_const, :FORMAT_NAMES
    end
  end

  test 'github-markup knows about gollum markups' do
    markups_with_render_filter = Gollum::Markup.formats.select do |k, v|
      case v[:skip_filters]
      when Array
        !v[:skip_filters].include?(:Render)
      when Proc
        !v[:skip_filters].call(:Render)
      else
        true
      end
    end
    markups_with_render_filter.each do |name, info|
      assert ::GitHub::Markup.markups.key?(name), "GitHub::Markup does not know about format #{name}"
    end
  end

  #########################################################################
  #
  # Links
  #
  #########################################################################

  test "absolute link to non-existent page" do
    @wiki.write_page("linktest", :markdown, "[[/Page]]", commit_details)

    page    = @wiki.page("linktest")
    doc     = Nokogiri::HTML page.formatted_data
    paras   = doc / :p
    para    = paras.first
    anchors = para / :a
    assert_equal 1, paras.size
    assert_equal 1, anchors.size
    assert_equal 'internal absent', anchors[0]['class']
    assert_equal '/Page', anchors[0]['href']
    assert_equal '/Page', anchors[0].text
  end
    
  test "absolute link link text" do
    @wiki.write_page("Docs/Integration/How the future will look", :markdown, "Bright", commit_details)
    @wiki.write_page("linktexttest", :markdown, "[[Docs/Integration/How the future will look.md]]", commit_details)
    page   = @wiki.page("linktexttest")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p><a class="internal present" href="/Docs/Integration/How%20the%20future%20will%20look.md">How the future will look</a></p>}, output
  end
  
  test "broken absolute link link text" do
    @wiki.write_page("linktexttest", :markdown, "[[/Docs/Integration/How the future will look.md]]", commit_details)
    page   = @wiki.page("linktexttest")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p><a class="internal absent" href="/Docs/Integration/How%20the%20future%20will%20look.md">/Docs/Integration/How the future will look.md</a></p>}, output  
  end

  test "double page links no space" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Foo]][[Bar]] b", commit_details)

    # "<p>a <a class=\"internal absent\" href=\"/Foo\">Foo</a><a class=\"internal absent\" href=\"/Bar\">Bar</a> b</p>"
    page    = @wiki.page("Bilbo Baggins")
    doc     = Nokogiri::HTML page.formatted_data
    paras   = doc / :p
    para    = paras.first
    anchors = para / :a
    assert_equal 1, paras.size
    assert_equal 2, anchors.size
    assert_equal 'internal absent', anchors[0]['class']
    assert_equal 'internal absent', anchors[1]['class']
    assert_equal '/Foo', anchors[0]['href']
    assert_equal '/Bar', anchors[1]['href']
    assert_equal 'Foo', anchors[0].text
    assert_equal 'Bar', anchors[1].text
  end

  test "double page links with space" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Foo]] [[Bar]] b", commit_details)

    # "<p>a <a class=\"internal absent\" href=\"/Foo\">Foo</a> <a class=\"internal absent\" href=\"/Bar\">Bar</a> b</p>"
    page    = @wiki.page("Bilbo Baggins")
    doc     = Nokogiri::HTML page.formatted_data
    paras   = doc / :p
    para    = paras.first
    anchors = para / :a
    assert_equal 1, paras.size
    assert_equal 2, anchors.size
    assert_equal 'internal absent', anchors[0]['class']
    assert_equal 'internal absent', anchors[1]['class']
    assert_equal '/Foo', anchors[0]['href']
    assert_equal '/Bar', anchors[1]['href']
    assert_equal 'Foo', anchors[0].text
    assert_equal 'Bar', anchors[1].text
  end

  test "page link" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Bilbo Baggins]] b", commit_details)

    page   = @wiki.page("Bilbo Baggins")
    output = page.formatted_data
    assert_match(/class="internal present"/, output)
    assert_match(/href="\/Bilbo%20Baggins.md"/, output)
    assert_match(/\>Bilbo Baggins\</, output)
  end

  test "adds nofollow to links on historical pages" do
    sha1 = @wiki.write_page("Sauron", :markdown, "a [[b]] c", commit_details)
    page = @wiki.page("Sauron")
    sha2 = @wiki.update_page(page, page.name, :markdown, "c [[b]] a", commit_details)
    regx = /rel="nofollow"/
    assert_no_match regx, page.formatted_data
    assert_match regx, @wiki.page(page.name, sha1).formatted_data
    assert_match regx, @wiki.page(page.name, sha2).formatted_data
  end

  test "absent page link" do
    @wiki.write_page("Tolkien", :markdown, "a [[J. R. R. Tolkien]]'s b", commit_details)

    page   = @wiki.page("Tolkien")
    output = page.formatted_data
    assert_match(/class="internal absent"/, output)
    assert_match(/href="\/J\.\%20R\.\%20R\.\%20Tolkien"/, output)
    assert_match(/\>J\. R\. R\. Tolkien\</, output)
  end

  test "page link with custom base path" do
    ["/wiki", "/wiki/"].each_with_index do |path, i|
      name  = "Bilbo Baggins #{i}"
      @wiki = Gollum::Wiki.new(@path, :base_path => path)
      @wiki.write_page(name, :markdown, "a [[#{name}]] b", commit_details)

      page   = @wiki.page(name)
      output = page.formatted_data
      assert_match(/class="internal present"/, output)
      assert_match(/href="\/wiki\/Bilbo\%20Baggins\%20\d.md"/, output)
      assert_match(/\>Bilbo Baggins \d\</, output)
    end
  end

  test "page link with included #" do
    @wiki.write_page("Precious #1", :markdown, "a [[Precious #1]] b", commit_details)
    page   = @wiki.page('Precious #1')
    output = page.formatted_data
    assert_match(/class="internal present"/, output)
    assert_match(/href="\/Precious\%20%231.md"/, output)
  end

  test "page link with multiple included #" do
    @wiki.write_page("Precious #1 #2", :markdown, "a [[Precious #1 #2]] b", commit_details)
    page   = @wiki.page('Precious #1 #2')
    output = page.formatted_data
    assert_match(/class="internal present"/, output)
    assert_match(/href="\/Precious\%20%231\%20%232.md"/, output)
  end

  test "page link with extra # and multiple included #{}" do
    @wiki.write_page("Potato #1 #2", :markdown, "a [[Potato #1 #2#anchor]] b", commit_details)
    page   = @wiki.page('Potato #1 #2')
    output = page.formatted_data
    assert_match(/class="internal present"/, output)
    assert_match(/href="\/Potato\%20%231\%20%232.md#anchor"/, output)
  end

  test "page link with extra #" do
    @wiki.write_page("Potato", :markdown, "a [[Potato#1]] b", commit_details)
    page   = @wiki.page('Potato')
    output = page.formatted_data
    assert_match(/class="internal present"/, output)
    assert_match(/href="\/Potato.md#1"/, output)
  end

  test "absent page link with extra #" do
    @wiki.write_page("Potato", :markdown, "a [[Tomato#1]] b", commit_details)
    page   = @wiki.page('Potato')
    output = page.formatted_data
    assert_match(/class="internal absent"/, output)
    assert_match(/href="\/Tomato#1"/, output)
  end

  test "external page link" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[http://example.com]] b", commit_details)
    page = @wiki.page("Bilbo Baggins")
    assert_html_equal "<p>a <a href=\"http://example.com\">http://example.com</a> b</p>", page.formatted_data
  end
  
  test "external page link with different text" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Words|http://example.com]] b", commit_details)
    page = @wiki.page("Bilbo Baggins")
    assert_html_equal "<p>a <a href=\"http://example.com\">Words</a> b</p>", page.formatted_data
  end

  test "external page link with agnostic protocol" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Words|//example.com]] b", commit_details)
    page = @wiki.page("Bilbo Baggins")
    assert_html_equal "<p>a <a href=\"//example.com\">Words</a> b</p>", page.formatted_data
  end

  test "page link with different text" do
    @wiki.write_page("Potato", :markdown, "a [[Potato Heaad|Potato]] ", commit_details)
    page   = @wiki.page("Potato")
    output = page.formatted_data
    assert_html_equal "<p>a<a class=\"internal present\" href=\"/Potato.md\">Potato Heaad</a></p>", output
  end

  test "page link with different text on mediawiki" do
    @wiki.write_page("Potato", :mediawiki, "a [[Potato|Potato Heaad]] ", commit_details)
    page   = @wiki.page("Potato")
    output = page.formatted_data
    assert_html_equal "<p>\na <a class=\"internal present\" href=\"/Potato.mediawiki\">Potato Heaad</a> </p>", output
  end

  test "page link with internal anchorlink only" do
    @wiki.write_page("Potato", :markdown, "# Test\nWaa\n[[Link Text|#test]] ", commit_details)
    page   = @wiki.page("Potato")
    output = page.formatted_data
    assert_html_equal "<h1 class=\"editable\"><a class=\"anchor\" id=\"test\" href=\"#test\"></a>Test</h1><p>Waa<br />\n<a class=\"internal anchorlink\" href=\"#test\">Link Text</a></p>", output
  end

  test "page link with internal anchorlink only on mediawiki" do
    @wiki.write_page("Potato", :mediawiki, "= Test =\nWaa\n[[#test|Link Text]] ", commit_details)
    page   = @wiki.page("Potato")
    output = page.formatted_data

    # Workaround for testing HTML equality, needed because of differences in nokogiri output on JRuby and MRI
    expected = "<h1 class=\"editable\"><a class=\"anchor\" "
    id = "id=\"test\""
    href = "href=\"#test\""
    if RUBY_PLATFORM == 'java'
      expected = expected << href << " " << id
    else
      expected = expected << id << " " << href
    end
    expected = expected << " ></a><a name=\"wiki-Test\""
    expected = expected << " id=\"wiki-Test\"" unless RUBY_PLATFORM == 'java'
    expected = expected << "></a><span class=\"mw-headline\" id=\"wiki-Test\">Test</span>\n</h1><p>Waa<a class=\"internal anchorlink\" href=\"#test\">Link Text</a></p>"

    assert_html_equal expected, output
  end


  test "wiki link within inline code block" do
    @wiki.write_page("Potato", :markdown, "`sed -i '' 's/[[:space:]]*$//'`", commit_details)
    page = @wiki.page("Potato")
    assert_html_equal "<p><code>sed -i '' 's/[[:space:]]*$//'</code></p>", page.formatted_data
  end

  test "wiki link within org code block" do
    code = <<-org
#+HEADERS: blah blah
#+HEADER: blah
#+NAME: org test block
  #+BEGIN_SRC bash some switches
sed -i '' 's/[[:space:]]*$//'
#+END_SRC
org
    @wiki.write_page("Pipe", :org, code, commit_details)
    page = @wiki.page("Pipe")
    assert_html_equal "<pre class=\"highlight\"><code><span class=\"nb\">sed</span> <span class=\"nt\">-i</span> <span class=\"s1\">''</span> <span class=\"s1\">'s/[[:space:]]*$//'</span></code></pre>\n",
                      page.formatted_data
  end

  test "regexp gsub! backref (#383)" do
    # bug only triggers on "```" syntax
    # not `code`
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
        (<<-'DATA'
  ```
  rot13='tr '\''A-Za-z'\'' '\''N-ZA-Mn-za-m'\'
  ```
        DATA
        ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre class=\"highlight\"><code>rot13='tr '\\''A-Za-z'\\'' '\\''N-ZA-Mn-za-m'\\'</code></pre>}
    assert_html_equal expected, output
  end

  test "backtick code blocks must have no more than three space indents" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(    ```ruby
'hi'
```
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre><code>```ruby 'hi' ```\n</code></pre>}
    assert_html_equal expected, output
  end

  # Issue #568
  test "tilde code blocks without a language" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(~~~
'hi'
~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre class=\"highlight\"><code>'hi'</code></pre>}

    assert_html_equal expected, output
  end

  test "tilde code blocks #537" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(~~~ruby
'hi'
~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre class=\"highlight\"><code><span class=\"s1\">'hi'</span></code></pre>}
    assert_html_equal expected, output
  end

  test "tilde code blocks must have no more than three space indents" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(    ~~~ruby
'hi'
~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre><code>~~~ruby 'hi' ~~~\n</code></pre>}
    assert_html_equal expected, output
  end

  test "tilde code blocks must have longer end tag than opening tag" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(~~~~ruby
'hi'
~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{\n}
    assert_html_equal expected, output
  end

  test "tilde code blocks with more than one word in info string" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(~~~ ruby bla
'hi'
~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre class=\"highlight\"><code><span class=\"s1\">'hi'</span></code></pre>}

    assert_html_equal expected, output
  end

  # Issue #537
  test "tilde code blocks with lots of tildes" do
    page = 'test_rgx'
    @wiki.write_page(page, :markdown,
                     %Q(~~~~~~ruby
~~
'hi'~
~~~~~~
      ), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %Q{<pre class=\"highlight\"><code><span class=\"o\">~~</span>\n<span class=\"s1\">'hi'</span><span class=\"o\">~</span></code></pre>}

    assert_html_equal expected, output
  end

  test "four space indented code block" do
    page = 'test_four'
    @wiki.write_page(page, :markdown,
                     %(    test
    test), commit_details)
    output   = @wiki.page(page).formatted_data
    expected = %(<pre><code>test\ntest\n</code></pre>)
    assert_html_equal expected, output
  end

  test "wiki link within code block" do
    @wiki.write_page("Potato", :markdown, "    sed -i '' 's/[[:space:]]*$//'", commit_details)
    page = @wiki.page("Potato")
    assert_html_equal "<pre><code>sed -i '' 's/[[:space:]]*$//'\n</code></pre>", page.formatted_data
  end

  test "piped wiki link within code block" do
    @wiki.write_page("Potato", :markdown, "`make a link [[home|sweet home]]`", commit_details)
    page = @wiki.page("Potato")
    assert_html_equal "<p><code>make a link [[home|sweet home]]</code></p>", page.formatted_data
  end

  #########################################################################
  #
  # include: directive
  #
  #########################################################################

  test "simple include: directive" do
    @wiki.write_page("page1", :textile, "hello\n[[include:page2]]\n", commit_details)
    @wiki.write_page("page2", :textile, "goodbye\n", commit_details)
    page1 = @wiki.page("page1")
    assert_html_equal("<p>hello<br/></p><p>goodbye</p>", page1.formatted_data)
  end

  test "include: directive with infinite loop" do
    @wiki.write_page("page1", :textile, "hello\n[[include:page1]]\n", commit_details)
    page1 = @wiki.page("page1")
    assert_match("Too many levels", page1.formatted_data)
  end

  test "include: directive with missing file" do
    @wiki.write_page("page1", :textile, "hello\n[[include:page2]]\n", commit_details)
    page1 = @wiki.page("page1")
    assert_match("Cannot include", page1.formatted_data)
  end

  test "include: directive with javascript" do
    @wiki.write_page("page1", :textile, "hello\n[[include:page2]]\n", commit_details)
    @wiki.write_page("page2", :textile, "<javascript>alert(99);</javascript>", commit_details)
    page1 = @wiki.page("page1")
    assert_html_equal("<p>hello<br/>\nalert(99);</p>", page1.formatted_data)
  end

  test "include: directive with sneaky javascript attempt" do
    @wiki.write_page("page1", :textile, "hello\n[[include:page2]][[include:page3]]\n", commit_details)
    @wiki.write_page("page2", :textile, "<java", commit_details)
    @wiki.write_page("page3", :textile, "script>alert(99);</javascript>", commit_details)
    page1 = @wiki.page("page1")
    assert_html_equal("<p>hello<br /></p><p>&lt;java</p><p>script&gt;alert(99);</p>", page1.formatted_data)
  end

  test "include directive with very long absolute path and relative include" do
    @wiki.write_page("page1", :textile, "hello\n[[include:/a/very/long/path/to/page2]]\n", commit_details)
    @wiki.write_page("/a/very/long/path/to/page2", :textile, "goodbye\n[[include:object]]", commit_details)
    @wiki.write_page("/a/very/long/path/to/object", :textile, "my love", commit_details)
    page1 = @wiki.page("page1")
    assert_html_equal("<p>hello<br/></p><p>goodbye<br/></p><p>my love</p>", page1.formatted_data)
  end

  test "include directive with a relative include" do
    @wiki.write_page("page1", :textile, "hello\n[[include:/going/in/deep]]\n", commit_details)
    @wiki.write_page("/going/in/deep", :textile, "[[include:../shallow]]", commit_details)
    @wiki.write_page("/going/shallow", :textile, "found me", commit_details)
    page1 = @wiki.page("page1")
    assert_html_equal("<p>hello<br/></p><p>found me</p>", page1.formatted_data)
  end

  test "relative include directive with a subtle infinite loop" do
    @wiki.write_page("page1", :textile, "hello\n[[include:../../page1]]\n", commit_details)
    page1 = @wiki.page("page1")
    assert_match("Too many levels", page1.formatted_data)
  end

  test "ugly include directives that should all be not found" do
    %w(

      ///
      ../../..
      /./.!!./
      ../../../etc/passwd
      con:
      /dev/null
      \0
      \\\\\\\\

    ).each_with_index do |ugly, n|

      name = "ugly#{n}"

      @wiki.write_page(name, :textile, "hello\n[[include:#{ugly}]]\n", commit_details)
      page1 = @wiki.page(name)
      assert_match("does not exist yet", page1.formatted_data)
    end
    %w(
      \ \ \ 
    ).each_with_index do |ugly, n|
      @wiki.write_page(name, :textile, "hello\n[[include:#{ugly}]]\n", commit_details)
      page1 = @wiki.page(name)
      assert_match("no page name given", page1.formatted_data)
    end
  end

  #########################################################################
  #
  # Images
  #
  #########################################################################

  test "image with http url" do
    ['http', 'https'].each do |scheme|
      name = "Bilbo Baggins #{scheme}"
      @wiki.write_page(name, :markdown, "a [[#{scheme}://example.com/bilbo.jpg]] b", commit_details)

      page   = @wiki.page(name)
      output = page.formatted_data
      assert_html_equal %{<p>a <img src=\"#{scheme}://example.com/bilbo.jpg\" /> b</p>}, output
    end
  end

  test "image with extension in caps with http url" do
    ['http', 'https'].each do |scheme|
      name = "Bilbo Baggins #{scheme}"
      @wiki.write_page(name, :markdown, "a [[#{scheme}://example.com/bilbo.JPG]] b", commit_details)

      page   = @wiki.page(name)
      output = page.formatted_data
      assert_html_equal %{<p>a <img src=\"#{scheme}://example.com/bilbo.JPG\" /> b</p>}, output
    end
  end

  test "image with absolute path" do
    @wiki = Gollum::Wiki.new(@path, :base_path => '/wiki')
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.commit("Add alpha.jpg")
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[/alpha.jpg]] [[a | /alpha.jpg]] b", commit_details)

    page = @wiki.page("Bilbo Baggins")
    assert_html_equal %{<p>a <img src=\"/wiki/alpha.jpg\" /><a href=\"/wiki/alpha.jpg\">a</a> b</p>}, page.formatted_data
  end

  test "image with relative path on root" do
    @wiki = Gollum::Wiki.new(@path, :base_path => '/wiki')
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.add("Bilbo-Baggins.md", "a [[alpha.jpg]] [[a | alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page = @wiki.page("Bilbo-Baggins")
    assert_html_equal %Q{<p>a <img src=\"/wiki/alpha.jpg\" /><a href=\"/wiki/alpha.jpg\">a</a> b</p>}, page.formatted_data
  end

  test "image with relative path" do
    @wiki = Gollum::Wiki.new(@path, :base_path => '/wiki')
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", "a [[alpha.jpg]] [[a | alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page   = @wiki.page("greek/Bilbo-Baggins")
    output = page.formatted_data
    assert_html_equal %{<p>a <img src=\"/wiki/greek/alpha.jpg\" /><a href=\"/wiki/greek/alpha.jpg\">a</a> b</p>}, output
  end

  test "image with absolute path on a preview" do
    @wiki = Gollum::Wiki.new(@path, :base_path => '/wiki')
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.commit("Add alpha.jpg")

    page = @wiki.preview_page("Test", "a [[/alpha.jpg]] b", :markdown)
    assert_html_equal %{<p>a <img src=\"/wiki/alpha.jpg\" /> b</p>}, page.formatted_data
  end

  test "image with relative path on a preview" do
    @wiki = Gollum::Wiki.new(@path, :base_path => '/wiki')
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.add("greek/alpha.jpg", "hi")
    index.commit("Add alpha.jpg")

    page = @wiki.preview_page("Test", "a [[alpha.jpg]] [[greek/alpha.jpg]] b", :markdown)
    assert_html_equal %{<p>a <img src=\"/wiki/alpha.jpg\" /><img src=\"/wiki/greek/alpha.jpg\" /> b</p>}, page.formatted_data
  end

  test "image with alt" do
    content = "a [[alpha.jpg|alt=Alpha Dog]] b"
    output  = %{<p>a<img src=\"/greek/alpha.jpg\" alt=\"Alpha Dog\"/>b</p>}
    relative_image(content, output)
  end

  test "image with em or px dimension" do
    %w{em px}.each do |unit|
      %w{width height}.each do |dim|
        content = "a [[alpha.jpg|#{dim}=100#{unit}]] b"
        output  = "<p>a<img src=\"/greek/alpha.jpg\" #{dim}=\"100#{unit}\"/>b</p>"
        relative_image(content, output)
      end
    end
  end

  test "image with bogus dimension" do
    %w{width height}.each do |dim|
      content = "a [[alpha.jpg|#{dim}=100]] b"
      output  = "<p>a<img src=\"/greek/alpha.jpg\"/>b</p>"
      relative_image(content, output)
    end
  end

  test "image with vertical align" do
    %w{top texttop middle absmiddle bottom absbottom baseline}.each do |align|
      content = "a [[alpha.jpg|align=#{align}]] b"
      output  = %Q{<p>a<img src=\"/greek/alpha.jpg\" align=\"#{align}\"/>b</p>}
      relative_image(content, output)
    end
  end

  test "image with horizontal align" do
    %w{left center right}.each do |align|
      content = "a [[alpha.jpg|align=#{align}]] b"
      text_align = align
      align = 'end' if align == 'right'
      output  = "<p>a<span class=\"d-flex flex-justify-#{align} text-#{text_align}\"><span><img src=\"/greek/alpha.jpg\"/></span></span>b</p>"
      relative_image(content, output)
    end
  end

  test "image with float" do
    content = "a\n\n[[alpha.jpg|float]]\n\nb"
    output  = "<p>a</p><p><span class=\"d-flex float-left pb-4\"><span><img src=\"/greek/alpha.jpg\"/></span></span></p><p>b</p>"
    relative_image(content, output)
  end

  test "image with float and align" do
    %w{left right}.each do |align|
      content = "a\n\n[[alpha.jpg|float, align=#{align}]]\n\nb"
      output  = "<p>a</p><p><span class=\"d-flex float-#{align} pb-4\"><span><img src=\"/greek/alpha.jpg\"/></span></span></p><p>b</p>"
      relative_image(content, output)
    end
  end

  test "image with frame" do
    content = "a\n\n[[alpha.jpg|frame]]\n\nb"
    output  = "<p>a</p><p><span class=\"d-flex \"><span class=\"border p-4\"><img src=\"/greek/alpha.jpg\"/></span></span></p><p>b</p>"
    relative_image(content, output)
  end

  test "absolute image with frame" do
    content = "a\n\n[[http://example.com/bilbo.jpg|frame]]\n\nb"
    output  = "<p>a</p><p><span class=\"d-flex \"><span class=\"border p-4\"><img src=\"http://example.com/bilbo.jpg\"/></span></span></p><p>b</p>"
    relative_image(content, output)
  end

  test "image with align and alt" do
    content = "a [[alpha.jpg|alt=Alpha Dog, align=center]] b"
    output  ="<p>a<span class=\"d-flex flex-justify-center text-center\"><span><img src=\"/greek/alpha.jpg\" alt=\"Alpha Dog\"/></span></span>b</p>"
    relative_image(content, output)
  end

  test "image with frame and alt" do
    content = "a\n\n[[alpha.jpg|frame, alt=Alpha]]\n\nb"
    output  = "<p>a</p><p><span class=\"d-flex \"><span class=\"border p-4\"><img src=\"/greek/alpha.jpg\" alt=\"Alpha\"/><span class=\"clearfix\">Alpha</span></span></span></p><p>b</p>"
    relative_image(content, output)
  end

  #########################################################################
  #
  # File links
  #
  #########################################################################

  test "file link without description" do
    index = @wiki.repo.index
    index.add("alpha.csv", "hi")
    index.commit("Add alpha.csv")
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[alpha.csv]] b", commit_details)

    page   = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a href="/alpha.csv">alpha.csv</a> b</p>}, output
  end

  test "file link with absolute path" do
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.commit("Add alpha.jpg")
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Alpha|/alpha.jpg]] b", commit_details)

    page   = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a href="/alpha.jpg">Alpha</a> b</p>}, output
  end
  
  test "page link with relative path" do
    index = @wiki.repo.index
    index.add('LinkedRelative.md', 'Hobbits are nice')
    index.add('greek/LinkedRelative.md', 'hi')
    index.add('greek/Foo.md', 'a [[LinkedRelative]] b')
    index.commit('Add Foo and Bar')
    
    page   = @wiki.page("greek/Foo")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a class="internal present" href="/greek/LinkedRelative.md">LinkedRelative</a> b</p>}, output 
  end
  
  test "page link with relative path into subdir" do
    index = @wiki.repo.index
    index.add('LinkedRelative.md', 'Hobbits are nice')
    index.add('greek/Subdir/LinkedRelative.md', 'hi')
    index.add('greek/Foo.md', 'a [[Subdir/LinkedRelative]] b')
    index.commit('Add Foo and Bar')
    
    page   = @wiki.page("greek/Foo")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a class="internal present" href="/greek/Subdir/LinkedRelative.md">LinkedRelative</a> b</p>}, output 
  end
  
  test "page link with absolute path" do
    index = @wiki.repo.index
    index.add('LinkedAbsolute.md', 'Hobbits are nice')
    index.add('greek/LinkedAbsolute.md', 'hi')
    index.add('greek/Foo.md', 'a [[/LinkedAbsolute]] b')
    index.commit('Add Foo and Bar')
    
    page   = @wiki.page("greek/Foo")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a class="internal present" href="/LinkedAbsolute.md">LinkedAbsolute</a> b</p>}, output   
  end

  test "file link with relative path is relative to root" do
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", "a [[Alpha|alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page   = @wiki.page("greek/Bilbo-Baggins")
    output = Gollum::Markup.new(page).render
    assert_html_equal %{<p>a <a href="/greek/alpha.jpg">Alpha</a> b</p>}, output
  end

  test "file link with external path" do
    index = @wiki.repo.index
    index.add("greek/Bilbo-Baggins.md", "a [[Alpha|http://example.com/alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page = @wiki.page("greek/Bilbo-Baggins")
    assert_html_equal %{<p>a <a href="http://example.com/alpha.jpg">Alpha</a> b</p>}, page.formatted_data
  end

  #########################################################################
  #
  # Code
  #
  #########################################################################

  test "regular code blocks" do
    content = "a\n\n```ruby\nx = 1\n```\n\nb"
    output  = %Q{<p>a</p>\n\n<pre class=\"highlight\"><code><span class=\"n\">x</span> <span class=\"o\">=</span> <span class=\"mi\">1</span></code></pre>\n\n<p>b</p>}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add alpha.jpg")

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_html_equal output, rendered
  end

  test "code blocks with carriage returns" do
    content = "a\r\n\r\n```ruby\r\nx = 1\r\n```\r\n\r\nb"
    output  = %Q{<p>a</p>\n\n<pre class=\"highlight\"><code><span class=\"n\">x</span> <span class=\"o\">=</span> <span class=\"mi\">1</span></code></pre>\n\n<p>b</p>}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add alpha.jpg")

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_html_equal output, rendered
  end

  test "code blocks with two-space indent" do
    content = "a\n\n```ruby\n  x = 1\n\n  y = 2\n```\n\nb"
    output  = "<p>a</p>\n\n<pre class=\"highlight\"><code><span class=\"n\">" +
        "x</span> <span class=\"o\">=</span> <span class=\"mi\">1" +
        "</span>\n\n<span class=\"n\">y</span> <span class=\"o\">=" +
        "</span> <span class=\"mi\">2</span>\n</code></pre>\n\n\n<p>b</p>"
    compare(content, output)
  end

  test "code blocks with one-tab indent" do
    content = "a\n\n```ruby\n\tx = 1\n\n\ty = 2\n```\n\nb"
    output  = "<p>a</p>\n\n<pre class=\"highlight\"><code><span class=\"n\">" +
        "x</span> <span class=\"o\">=</span> <span class=\"mi\">1" +
        "</span>\n\n<span class=\"n\">y</span> <span class=\"o\">=" +
        "</span> <span class=\"mi\">2</span>\n</code></pre>\n\n\n<p>b</p>"
    compare(content, output)
  end

  test "code blocks with multibyte characters indent" do
    content = "a\n\n```ruby\ns = 'やくしまるえつこ'\n```\n\nb"
    output  = %Q{<p>a</p>\n\n<pre class=\"highlight\"><code><span class=\"n\">s</span> <span class=\"o\">=</span> <span class=\"s1\">'やくしまるえつこ'</span></code></pre>\n\n<p>b</p>}
    index   = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add alpha.jpg")

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render(false, 'utf-8')
    assert_html_equal output, rendered
  end

  test "code blocks with ascii characters" do
    content = "a\n\n```\n├─foo\n```\n\nb"
    output  = %(<p>a</p><pre class=\"highlight\"><code>├─foo</code></pre><p>b</p>)
    compare(content, output)
  end

  test "code with wiki links" do
    content = <<-END
booya

``` python
np.array([[2,2],[1,3]],np.float)
```
    END

    _page, rendered = render_page(content)
    assert_markup_highlights_code rendered
  end

  test "code with trailing whitespace" do
    content = <<-END
shoop da woop

``` python
np.array([[2,2],[1,3]],np.float)
```
    END

    # rendered with Gollum::Markup
    _page, rendered = render_page(content)
    assert_markup_highlights_code rendered
  end

  def assert_markup_highlights_code(rendered)
    assert_match(/pre class="highlight"/, rendered, "Gollum::Markup doesn't highlight code\n #{rendered}")
    assert_match(/span class="n"/, rendered, "Gollum::Markup doesn't highlight code\n #{rendered}")
    assert_match(/\(\[\[/, rendered, "Gollum::Markup parses out wiki links\n#{rendered}")
  end

  test "embed code page absolute link" do
    @wiki.write_page("base", :markdown, "a\n!base", commit_details)
    @wiki.write_page("a", :markdown, "a\n```html:/base```", commit_details)

    page   = @wiki.page("a")
    output = page.formatted_data
    assert_html_equal %Q{<p>a\n</p><p class="gollum-error">File not found: /base</p>}, output
  end

  test "embed code page relative link" do
    @wiki.write_page("base", :markdown, "a\n!rel", commit_details)
    @wiki.write_page("a", :markdown, "a\n```html:base```", commit_details)

    page   = @wiki.page("a")
    output = page.formatted_data
    assert_html_equal %Q{<p>a\n</p><p class="gollum-error">File not found: base</p>}, output
  end

  test "code block in unsupported language" do
    @wiki.write_page("a", :markdown, "a\n\n```nonexistent\ncode\n```", commit_details)

    page   = @wiki.page("a")
    output = page.formatted_data
    assert_html_equal %Q{<p>a\n</p><pre class=\"highlight\"><span class=\"err\">code</span></pre>}, output
  end

  #########################################################################
  #
  # YAML Frontmatter
  #
  #########################################################################

  test "yaml frontmatter" do
    content = "---\ntitle: YAML in Middle Earth\ntags: [foo, bar]\n---\nSome more content"
    output = "Some more content\n"
    result = {'title' => 'YAML in Middle Earth', 'tags' => ['foo', 'bar']}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add metadata")    

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered.gsub(/<(\/)?p>/,'')
    assert_equal result, page.metadata
  end


  test "yaml frontmatter with dots" do
    content = "---\ntitle: YAML in Middle Earth\ntags: [foo, bar]\n...\nSome more content"
    output = "Some more content\n"
    result = {'title' => 'YAML in Middle Earth', 'tags' => ['foo', 'bar']}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add metadata")    

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered.gsub(/<(\/)?p>/,'')
    assert_equal result, page.metadata
  end

  test "yaml sanitation" do
    content = "---\ntitle: YAML in Middle <script type='text/javascript'>document.write('hello world!');</script>Earth\n...\nSome more content"
    result = {'title' => 'YAML in Middle Earth'}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add metadata")    

    page     = @wiki.page("Bilbo-Baggins")
    assert_equal result, page.metadata
  end

  test "yaml frontmatter with invalid YAML 1" do
    content = "---\ntitle: YAML in Middle Earth\nFrodo\n...\nSome more content"
    output = "Some more content\n"

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add metadata")    

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered.gsub(/<(\/)?p>/,'')
    assert_equal 1, page.metadata.size
    assert_match /Failed to load YAML frontmater:/, page.metadata['errors'].first
  end

  test "yaml frontmatter with invalid YAML 2" do
    content = "---\ntitle\n...\nSome more content"
    output = "Some more content\n"
    result = {}

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.md", content)
    index.commit("Add metadata")    

    page     = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered.gsub(/<(\/)?p>/,'')
    assert_equal result, page.metadata
  end

  #########################################################################
  #
  # Various
  #
  #########################################################################

  test "strips javscript protocol urls" do
    content = "[Hack me](javascript:hacked=true)"
    output  = "<p><a>Hack me</a></p>"
    compare(content, output)
  end

  test "allows apt uri schemes" do
    content = "[Hack me](apt:gettext)"
    output  = "<p><a href=\"apt:gettext\">Hack me</a></p>"
    compare(content, output)
  end

  test "removes style blocks completely" do
    content = "<style>body { color: red }</style>foobar"
    output  = "<p>foobar</p>"
    compare(content, output)
  end

  test "removes script blocks completely" do
    content = "<script>alert('hax');</script>foobar"
    output  = "<p>foobar</p>"
    compare(content, output)
  end

  test "escaped wiki link" do
    content = "a '[[Foo]], b"
    output  = "<p>a [[Foo]], b</p>"
    compare(content, output)
  end

  test "quoted wiki link" do
    content = "a '[[Foo]]', b"
    output  = "<p>a '<a class=\"internal absent\" href=\"/Foo\">Foo</a>', b</p>"
    compare(content, output, 'md', [
        /class="internal absent"/,
        /href="\/Foo"/,
        /\>Foo\</])
  end

  test "org mode style double links" do
    content = "a [[http://google.com][Google]] b"
    output  = "<p>a <a href=\"http://google.com\">Google</a> b</p>"
    compare(content, output, 'org')
  end

  test "org mode style double file links" do
    content = "a [[file:f.org][Google]] b"
    output  = "<p>a <a class=\"internal absent\" href=\"/f\">Google</a> b</p>"
    compare(content, output, 'org')
  end

  test "short double links" do
    content = "a [[b]] c"
    output  = %(<p>a <a class="internal absent" href="/b">b</a> c</p>)
    compare(content, output, 'org')
  end

  test "double linked pipe" do
    content = "a [[|]] b"
    output  = %(<p>a <a class="internal absent" href="/"></a> b</p>)
    compare(content, output, 'org')
  end

  test "id with prefix ok" do
    content = "h2(example#wiki-foo). xxxx"
    output  = "<h2 class=\"example editable\" id=\"wiki-foo\"><a class=\"anchor\" id=\"xxxx\" href=\"#xxxx\"></i></a>xxxx</h2>"
    compare(content, output, :textile)
  end

  test "id prefix added" do
    content = "h2(#foo). xxxx[1]\n\nfn1.footnote"
    output  = "<h2 class=\"editable\" id=\"wiki-foo\"><a class=\"anchor\" id=\"xxxx1\" href=\"#xxxx1\"></a>xxxx<sup class=\"footnote\" id=\"wiki-fnr1\"><a href=\"#wiki-fn1\">1</a></sup>\n</h2>\n<p class=\"footnote\" id=\"wiki-fn1\"><a href=\"#wiki-fnr1\"><sup>1</sup></a> footnote</p>"
    compare(content, output, :textile)
  end

  test "name prefix added" do
    content = "abc\n\n__TOC__\n\n==Header==\n\nblah"
    compare content, '', :mediawiki, [
        /id="wiki-toc"/,
        /href="#wiki-Header"/,
        /id="wiki-Header"/,
        /name="wiki-Header"/
    ]
  end

  test "adds editable class to headers in the source document" do
    content = '# Test'
    output = '<h1 class="editable"><a class="anchor" id="test" href="#test"></a>Test</h1>'
    compare(content, output, :markdown)
  end

  test "does not add editable class to headers in the source document when it contains placeholder" do
    content = '# Test %SomeFilter%BLA=SomeFilter='
    output = '<h1><a class="anchor" id="test-somefilter-bla-somefilter" href="#test-somefilter-bla-somefilter"></a>Test %SomeFilter%BLA=SomeFilter=</h1'
    compare(content, output, :markdown)
  end
  
  test "toc with h1_title does not include page title" do
    @wiki.instance_variable_set(:@h1_title, true)
    @wiki.write_page("H1Test", :markdown, "# This is the page title\n\n# Testing\n\nTest", commit_details)
    page = @wiki.page("H1Test")
    assert_html_equal page.toc_data, "<div class=\"toc\"><div class=\"toc-title\">Table of Contents</div><ul><li><a href=\"#testing\">Testing</a></li></ul></div>"
    @wiki.instance_variable_set(:@h1_title, false)
  end

  test "identical headers in TOC have unique prefix" do
    content = <<-MARKDOWN
__TOC__

# Summary

# Summary
    MARKDOWN

    output = "<p><strong>TOC</strong></p>\n\n<h1 class=\"editable\"><a class=\"anchor\" id=\"summary\" href=\"#summary\"></a>Summary</h1>\n\n<h1 class=\"editable\"><a class=\"anchor\" id=\"summary-1\" href=\"#summary-1\"></a>Summary</h1>"
    compare(content, output, :markdown)
  end

  test "anchor names are normalized" do
    content = <<-MARKDOWN
__TOC__

# Summary '"' stuff

# Summary !@$#%^&*() stuff
    MARKDOWN

    output = "<p><strong>TOC</strong></p>\n\n<h1 class=\"editable\"><a class=\"anchor\" id=\"summary-stuff\" href=\"#summary-stuff\"></a>Summary '\"' stuff</h1>\n\n<h1  class=\"editable\"><a class=\"anchor\" id=\"summary-stuff-1\" href=\"#summary-stuff-1\"></a>Summary !@$#%^&*() stuff</h1>"
    compare(content, output, :markdown)
  end

  test 'anchor names are unique' do
    content = <<-MARKDOWN
__TOC__

# Summary

## Horse

# Summary

### Horse
    MARKDOWN

    output = "<p><strong>TOC</strong></p>\n\n<h1 class=\"editable\"><a class=\"anchor\" id=\"summary\" href=\"#summary\"></a>Summary</h1>\n\n<h2 class=\"editable\"><a class=\"anchor\" id=\"horse\" href=\"#horse\"></a>Horse</h2>\n<h1 class=\"editable\"><a class=\"anchor\" id=\"summary-1\" href=\"#summary-1\"></a>Summary</h1>\n\n<h3 class=\"editable\"><a class=\"anchor\" id=\"horse-1\" href=\"#horse-1\"></a>Horse</h3>"
    compare(content, output, :markdown)
  end


  if defined?(Asciidoctor)
    #########################################################################
    # Asciidoc
    #########################################################################
    test "asciidoc syntax highlighting" do
      input = <<-ASCIIDOC
[source,python]
----
''' A multi-line
    comment.'''
def sub_word(mo):
    ''' Single line comment.'''
    word = mo.group('word')   # Inline comment
    if word in keywords[language]:
        return quote + word + quote
    else:
        return word
----
      ASCIIDOC
      compare(input, nil, 'asciidoc', [/\<code\>\<span class=\"s\">''' A multi-line\n    comment.'''\<\/span\>/])
    end

    test "asciidoc header" do
      compare("= Book Title\n\n== Heading", '<div class="sect1"><h2 id="wiki-_heading">Heading<a class="anchor" id="Heading" href="#Heading"></a></h2><div class="sectionbody"></div></div>', 'asciidoc')
    end

    test "internal links with asciidoc" do
      compare("= Book Title\n\n[[anid]]\n== Heading", '<div class="sect1"><h2 id="wiki-anid">Heading<a class="anchor" id="Heading" href="#Heading"></a></h2><div class="sectionbody"></div></div>', 'asciidoc')
    end
  end

  #########################################################################
  # Plain Text
  #########################################################################

  test "plain text (.txt) is rendered within a <pre></pre> block" do
    content = "In the Land of Mordor where the Shadows lie."
    output  = "<pre>In the Land of Mordor where the Shadows lie.</pre>"
    compare(content, output, "txt")
  end

  test "plain text (.txt) is rendered without code blocks" do
    content = "```ruby\nx = 1\n```\n"
    output  = "<pre>```ruby\nx = 1\n```\n</pre>"
    compare(content, output, "txt")
  end

  test "plain text (.txt) is rendered without markdown markup" do
    content = "# A basic header"
    output  = "<pre># A basic header</pre>"
    compare(content, output, "txt")
  end

  test "plain text (.txt) is rendered with meta data" do
    content = "---\ntags: [foo, bar]\n---\nb"
    result  = { 'tags' => ['foo', 'bar'] }
    output  = "<pre>b</pre>"

    index = @wiki.repo.index
    index.add("Bilbo-Baggins.txt", content)
    index.commit("Plain Text with metadata")

    page = @wiki.page("Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered
    assert_equal result, page.metadata
  end

  test "plain text (.txt) is rendered with inline HTML escaped" do
    content = "Plain text <br/> with a <a href=\"http://example.com\">HTML link</a>"
    output  = "<pre>Plain text &lt;br/&gt; with a &lt;a href=\"http://example.com\"&gt;HTML link&lt;/a&gt;</pre>"
    compare(content, output, "txt")
  end

  #########################################################################
  #
  # Helpers
  #
  #########################################################################

  def render_page(content, ext = "md")
    index = @wiki.repo.index
    index.add("Bilbo-Baggins.#{ext}", content)
    index.commit("Add baggins")

    page = @wiki.page("Bilbo-Baggins")
    [page, Gollum::Markup.new(page).render]
  end

  def compare(content, output, ext = "md", regexes = [])
    page, rendered = render_page(content, ext)

    if regexes.empty?
      assert_html_equal output, rendered
    else
      output = page.formatted_data
      regexes.each { |r| assert_match r, output }
    end
  end

  def relative_image(content, output)
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", content)
    index.commit("Add alpha.jpg")

    @wiki.clear_cache
    page     = @wiki.page("greek/Bilbo-Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_html_equal output, rendered
  end
end
