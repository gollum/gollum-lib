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

  test "Missing macro provides missing macro output" do
    @wiki.write_page("NonExistentPage", :markdown, "<<NonExistentMacro()>>", commit_details)
    assert_match /Unknown macro: NonExistentMacro/, @wiki.pages[0].formatted_data
  end

  test "AllPages macro does something interesting" do
    @wiki.write_page("AllPagesMacroPage", :markdown, "<<AllPages()>>", commit_details)
    assert_match /<li>AllPagesMacroPage/, @wiki.pages[0].formatted_data
  end
  
  test "ListArgs with no args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs()>>", commit_details)
    assert_no_match /@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with a single empty quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("")>>', commit_details)
    assert_match /@@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with a single non-quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs(foo)>>", commit_details)
    assert_match /@foo@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with several single non-quoted args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, "<<ListArgs(foo, bar,baz)>>", commit_details)
    assert_match /@foo@/, @wiki.pages[0].formatted_data
    assert_match /@bar@/, @wiki.pages[0].formatted_data
    assert_match /@baz@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with a single quoted arg" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz")>>', commit_details)
    assert_match /@foo, bar, and baz@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with several quoted args" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz", "wombat", "xyzzy")>>', commit_details)
    assert_match /@foo, bar, and baz@/, @wiki.pages[0].formatted_data
    assert_match /@wombat@/, @wiki.pages[0].formatted_data
    assert_match /@xyzzy@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with quoted parens" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs(foo, "(bar)")>>', commit_details)
    assert_match /@foo@/, @wiki.pages[0].formatted_data
    assert_match /@\(bar\)@/, @wiki.pages[0].formatted_data
  end

  test "ListArgs with a mix or arg styles" do
    @wiki.write_page("ListArgsMacroPage", :markdown, '<<ListArgs("foo, bar, and baz", wombat, funny things)>>', commit_details)
    assert_match /@foo, bar, and baz@/, @wiki.pages[0].formatted_data
    assert_match /@wombat@/, @wiki.pages[0].formatted_data
    assert_match /@funny things@/, @wiki.pages[0].formatted_data
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
end
