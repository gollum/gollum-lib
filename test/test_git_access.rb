# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "GitAccess" do
  setup do
    @access = Gollum::GitAccess.new(testpath("examples/lotr.git"))
  end

  test "#commit fills commit_map cache" do
    actual   = @access.repo.commits.first
    expected = @access.commit(actual.id)

    assert_equal actual.message, expected.message
    assert_equal actual.message, @access.get_cache("commit", actual.id).message
  end

  test "#tree_map_for caches ref and tree" do
    @access.tree 'master'
    assert_equal "874f597a5659b4c3b153674ea04e406ff393975e", @access.get_cache("ref", "master")

    @access.tree '1db89ebba7e2c14d93b94ff98cfa3708a4f0d4e3'
    map = @access.get_cache("tree", "1db89ebba7e2c14d93b94ff98cfa3708a4f0d4e3")
    assert_equal 'Bilbo-Baggins.md',        map[0].path
    assert_equal '',                        map[0].dir
    assert_equal map[0].path,               map[0].name
    assert_equal 'Mordor/Eye-Of-Sauron.md', map[3].path
    assert_equal '/Mordor',                 map[3].dir
    assert_equal 'Eye-Of-Sauron.md',        map[3].name
  end

  test "#tree_map_for only caches tree for commit" do
    @access.tree '60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'

    entries = @access.get_cache("tree", "60f12f4254f58801b9ee7db7bca5fa8aeefaa56b")
    assert_equal 'Bilbo-Baggins.md', entries.first.path
  end

  test "cannot access commit from invalid ref" do
    assert_nil @access.commit('foo')
  end

  test "cannot access sha from invalid ref" do
    assert_nil @access.ref_to_sha('foo')
  end

  test "cannot access tree from invalid ref" do
    assert_equal [], @access.tree('foo')
  end

  test "sets #mode for blob entries" do
    @access.tree '60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'
    file = @access.get_cache(:tree, '60f12f4254f58801b9ee7db7bca5fa8aeefaa56b').first
    assert_equal 0100644, file.mode

    @access.tree '874f597a5659b4c3b153674ea04e406ff393975e'
    symlink = @access.get_cache(:tree, '874f597a5659b4c3b153674ea04e406ff393975e').find { |entry| entry.name == 'Data-Two.csv' }
    assert_not_nil symlink
    assert_equal 0120000, symlink.mode
  end
end
