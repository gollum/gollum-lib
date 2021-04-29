# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), 'helper')
require File.expand_path(path)

context 'Wiki search rank' do

  setup do
    @path = cloned_testpath('examples/lotr.git')
    @wiki = Gollum::Wiki.new(@path, :page_file_dir => 'Rivendell')

    @test_text = '# Using a search rank in Gollum
Gollum uses a search rank to determine how good a found result matches
the given search terms.
## Example-Title with another mention of Gollum
further text and even [a link](http://somewhere.local) to some Gollum documentation'

  end

  test 'rank exists' do
    results = @wiki.count_matches(nil, nil)
    assert_equal [0,0,0,0], results
  end

  test 'rank search matches title' do
    results = @wiki.count_matches(@test_text, 'Using a search rank in Gollum')
    assert_equal [1, 0, 0, 1], results
  end

  test 'rank search matches chapter' do
    results = @wiki.count_matches(@test_text, 'Example-Title with another mention of Gollum')
    assert_equal [0, 1, 0, 1], results
  end

  test 'rank search matches link' do
    results = @wiki.count_matches(@test_text, 'a link')
    assert_equal [0, 0, 1, 1], results
  end

  test 'rank search matches any other occurrence' do
     results = @wiki.count_matches(@test_text, 'text')
     assert_equal [0, 0, 0, 1], results
   end

  test 'rank search matches tile partially' do
    results = @wiki.count_matches(@test_text, 'search rank')
    assert_equal [1, 0, 0, 2], results
  end

  test 'rank search matches chapter partially' do
    results = @wiki.count_matches(@test_text, 'Title')
    assert_equal [0, 1, 0, 1], results
  end

  test 'rank search matches link partially' do
    results = @wiki.count_matches(@test_text, 'link')
    assert_equal [0, 0, 1, 1], results
  end

  test 'rank search matches for Gollum' do
    results = @wiki.count_matches(@test_text, 'Gollum')
    assert_equal [1, 1, 0, 4], results
  end

  test 'rank search without any matches' do
    results = @wiki.count_matches(@test_text, 'is not found in text')
    assert_equal [0, 0, 0, 0], results
  end

  test 'weigh_rank with full topic match' do
    ranks = [1, 0, 0, 0]
    result = @wiki.weigh_rank(ranks)
    assert_equal 50, result
  end

  test 'weigh_rank with full chapter match' do
    ranks = [0, 2, 0, 0]
    result = @wiki.weigh_rank(ranks)
    assert_equal 25, result
  end

  test 'weigh_rank with full link matches' do
    ranks = [0, 0, 2, 0]
    result = @wiki.weigh_rank(ranks)
    assert_equal 15, result
  end

  test 'weigh_rank with full hit matches' do
    ranks = [0, 0, 0, 5]
    result = @wiki.weigh_rank(ranks)
    assert_equal 10, result
  end

  test 'weigh_rank with over full hit matches' do
    ranks = [0, 0, 0, 15]
    result = @wiki.weigh_rank(ranks)
    assert_equal 10, result
  end

  teardown do
    FileUtils.rm_rf(@path)
  end
end
