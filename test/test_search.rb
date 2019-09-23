# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), 'helper')
require File.expand_path(path)

context 'Wiki search' do

  SEARCH_TEST_PAGE = <<EOF
Hobbits are small. Hobbits live in Hobbiton.
One thing Hobbits do not like is Orcs.
Something a hobbit does like is pastry.
ᚠᛇᚻ᛫ᛒᛦᚦ᛫ᚠᚱᚩᚠᚢᚱ᛫ᚠᛁᚱᚪ᛫ᚷᛖᚻᚹᛦᛚᚳᚢᛗ
EOF

  SEARCH_TEST_LINES = SEARCH_TEST_PAGE.split(/[\n\r]+/)

  setup do
    @path = cloned_testpath('examples/lotr.git')
    @wiki = Gollum::Wiki.new(@path, :page_file_dir => 'Rivendell')
    @wiki.write_page('bar', :markdown, 'bar', commit_details)
    @wiki.write_page('filename:with:colons', :markdown, '# Filename with colons', commit_details)
    @wiki.write_page('foo', :markdown, "# File with query in contents and filename\nfoo", commit_details)
    @wiki.write_page('Hobbit Info', :markdown, SEARCH_TEST_PAGE, commit_details)
  end
  
  test 'search results should be able to return a filename with an embedded colon' do
    results = @wiki.search('colons').first
    assert_not_nil results
    result = results.first
    assert_equal 'filename:with:colons.md', result[:name]
    assert_equal 1, result[:count]
    assert_equal 1, result[:filename_count]
  end

  test 'search finds utf8' do
    results = @wiki.search('ᚠ').first
    assert_equal 1, results.count
    assert_equal 'Hobbit Info.md', results.first[:name]
  end

  test 'search results should include filename hits' do
    results = @wiki.search('Hobbit Info').first
    assert_equal 2, results.first[:filename_count]
  end

  test 'search results should not include files that do not match the query' do
    results = @wiki.search('foo').first
    assert_equal 1, results.size
    assert_not_equal 'bar.md', results.first[:name]
    assert_equal 'foo.md', results.first[:name]
  end

  test 'search should support multiple search terms ' do
    results = @wiki.search('foo bar').first
    assert_equal 2, results.size
    assert_equal 'bar.md', results.first[:name]
    assert_equal 'foo.md', results.last[:name]

    results = @wiki.search('Hobbits pastry').first
    assert_equal 1, results.size
    assert_equal 4, results.first[:count]
    assert_equal SEARCH_TEST_LINES[2], results.first[:context].last
  end

  test 'search should respect quoted search terms' do
    results = @wiki.search('like is pastry').first
    hobbit_info_result = results.find {|result| result[:name] == 'Hobbit Info.md'}
    assert_equal 5, hobbit_info_result[:count]
    results = @wiki.search('"like is" pastry').first
    assert_equal 3, results.first[:count]
  end

  test 'search should be case insensitive' do
    results = @wiki.search('Hobbit').first
    hobbit_info_result = results.find {|result| result[:name] == 'Hobbit Info.md'}
    assert hobbit_info_result[:context][2].include?('hobbit')
    assert !hobbit_info_result[:context][2].include?('Hobbit')
  end

  test 'search should return context for hits' do
    results = @wiki.search('Hobbit').first
    context = results.first[:context]
    assert_not_nil context
    context.each do |ct|
      assert_equal 1, ct.lines.length
    end
    assert context.include?(SEARCH_TEST_LINES[0])
    assert context.include?(SEARCH_TEST_LINES[1])
    assert context.include?(SEARCH_TEST_LINES[2])
    assert !context.include?(SEARCH_TEST_LINES[3])
  end

  test 'search results when only filename matches' do
    results = @wiki.search('Info').first
    assert_equal 1, results.length
    assert_equal 'Hobbit Info.md', results.first[:name]
    assert_equal [], results.first[:context]
  end

  test 'search returns escaped search terms on demand' do
    result, search_terms = @wiki.search('foo|bar')
    assert_nil search_terms
    result, search_terms = @wiki.search('foo|bar', true)
    assert_equal 'foo\|bar', search_terms.first
  end

  test 'search should respect page_file_dir' do
    results = @wiki.search('Hobbit').first
    # Do not match the word 'Hobbit' in Bilbo-Baggins.md in the root directory
    assert_equal 1, results.length
    assert !results.first[:name].include?('Rivendell')
  end
  
  teardown do
    FileUtils.rm_rf(@path)
  end
end