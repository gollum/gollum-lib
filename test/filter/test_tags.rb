
# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::Tags" do
  setup do
    @path          = cloned_testpath('examples/page_file_dir')
    @page_file_dir = 'docs'
    @wiki          = Gollum::Wiki.new(@path, :page_file_dir => @page_file_dir)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "tag processing time is not exponential in number of tags" do
    TAGCOUNT = 500
    page_with_many_tags = (0..TAGCOUNT).map { |i| "<tt>[[#{i}]]</tt>"}.join
    page_name = "page with many tags"
    @wiki.write_page(page_name, :markdown, page_with_many_tags, commit_details)
    page = @wiki.page(page_name)
    markup = Gollum::Markup.new(page)
    filter = Gollum::Filter::Tags.new(markup)
    data_with_placeholders = filter.extract(page.raw_data)
    max_seconds = RUBY_PLATFORM == "java" ? 3 : 2
    assert_max_seconds(max_seconds, "tag processing for #{TAGCOUNT} tags") do
      data_processed = filter.process(data_with_placeholders)
      assert_equal page_with_many_tags, data_processed
    end
  end
end
