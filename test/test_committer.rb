# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Wiki" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "normalizes commit hash" do
    commit    = { :message => 'abc' }
    name      = @wiki.default_committer_name
    email     = @wiki.default_committer_email
    committer = Gollum::Committer.new(@wiki, commit)
    assert_equal name, committer.actor.name
    assert_equal email, committer.actor.email

    commit[:name]  = ''
    commit[:email] = ''
    committer      = Gollum::Committer.new(@wiki, commit)
    assert_equal '', committer.actor.name
    assert_equal '', committer.actor.email

    commit[:name]  = nil
    commit[:email] = nil
    committer      = Gollum::Committer.new(@wiki, commit)
    assert_equal name, committer.actor.name
    assert_equal email, committer.actor.email
    assert_equal nil, committer.actor.time

    commit[:name]  = 'bob'
    commit[:email] = nil
    commit[:time] = nil
    committer      = Gollum::Committer.new(@wiki, commit)
    assert_equal 'bob', committer.actor.name
    assert_equal email, committer.actor.email
    assert_equal nil, committer.actor.time

    commit[:name]  = nil
    commit[:email] = 'foo@bar.com'
    commit[:time] = Time.parse('2020-02-14')
    committer      = Gollum::Committer.new(@wiki, commit)
    assert_equal name, committer.actor.name
    assert_equal 'foo@bar.com', committer.actor.email
    assert_equal Time.parse('2020-02-14'), committer.actor.time
  end

  test "yield after_commit callback" do
    @path   = cloned_testpath('examples/lotr.git')
    yielded = nil
    begin
      wiki      = Gollum::Wiki.new(@path)
      committer = Gollum::Committer.new(wiki)
      committer.after_commit do |index, sha1|
        yielded = sha1
        assert_equal committer, index
      end

      res = wiki.write_page("Gollum", :markdown, "# Gollum",
                            :committer => committer)

      assert_equal committer, res

      sha1 = committer.commit
      assert_equal sha1, yielded
    ensure
      FileUtils.rm_rf(@path)
    end
  end

  test "post_commit hooks called after committing" do
    @path   = cloned_testpath('examples/lotr.git')
    yielded = nil
    begin
      wiki      = Gollum::Wiki.new(@path)
      committer = Gollum::Committer.new(wiki)
      Gollum::Hook.register(:post_commit, :hook) do |index, sha1|
        yielded = sha1
        assert_equal committer, index
      end

      res = wiki.write_page("Gollum", :markdown, "# Gollum",
                            :committer => committer)

      assert_equal committer, res

      sha1 = committer.commit
      assert_equal sha1, yielded
    ensure
      Gollum::Hook.unregister(:post_commit, :hook)
      FileUtils.rm_rf(@path)
    end
  end

  test "parents with default master ref" do
    ref       = '1b6a36a7ac19f260fcf02bee1b962edb2cec6176'
    committer = Gollum::Committer.new(@wiki)
    assert_equal ref, committer.parents.first.sha
  end

  test "parents with custom ref" do
    ref       = '60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'
    @wiki     = Gollum::Wiki.new(testpath("examples/lotr.git"), :ref => ref)
    committer = Gollum::Committer.new(@wiki)
    assert_equal ref, committer.parents.first.sha
  end


  test "update working directory with page file directory and subdirectory for a new page" do
    page_file_dir = "foo"
    dir           = "/bar"
    name          = "baz"
    format        = :markdown
    @wiki         = Gollum::Wiki.new(testpath("examples/lotr.git"), { :page_file_dir => page_file_dir })

    @wiki.repo.stubs(:bare).returns(false)
    Gollum::Committer.any_instance.stubs(:add_to_index).returns(true)
    Gollum::Git::Index.any_instance.stubs(:commit).returns(true)

    @wiki.repo.git.expects(:checkout).with("#{page_file_dir}#{dir}/#{name}.md", "HEAD")
    @wiki.write_page(File.join(dir, name), format, "foo bar baz", commit_details)
  end

  test "update working directory with page file directory and subdirectory for an existing page" do
    page_file_dir = "Rivendell"
    name          = "Elrond"
    format        = :markdown
    @wiki         = Gollum::Wiki.new(testpath("examples/lotr.git"), { :page_file_dir => page_file_dir })

    @wiki.repo.stubs(:bare).returns(false)
    Gollum::Git::Index.any_instance.stubs(:commit).returns(true)

    page = @wiki.page(name)

    @wiki.repo.git.expects(:checkout).at_least(1).with("#{page_file_dir}/#{name}.md", "HEAD")
    @wiki.update_page(page, page.name, format, "# Elrond", commit_details())
  end
end

context "Committer with a writable wiki" do
  setup do
    @path = cloned_testpath("examples/lotr.git")
    @wiki = Gollum::Wiki.new(@path)
  end

  test "supports notes" do
    committer = Gollum::Committer.new(@wiki, note: 'My notes')
    committer.commit
    assert_equal @wiki.repo.head.commit.note, 'My notes'
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end