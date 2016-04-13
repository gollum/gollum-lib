
# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::Emoji" do
  setup do
    @filter = Gollum::Filter::Emoji.new(Gollum::Markup.new(nil))
  end

  test "processing emoji tags" do
    assert_equal @filter.process(':heart:'), %Q(<img src="/emoji/heart" alt="heart" class="emoji">)
  end
end
