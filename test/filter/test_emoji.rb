# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::Emoji" do
  setup do
    @filter = Gollum::Filter::Emoji.new(Gollum::Markup.new(mock_page))
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  test "processing emoji tags" do
    assert_equal filter(':heart:'), %q(<img src="/gollum/emoji/heart" alt="heart" class="emoji">)
    assert_equal filter(':point_up_tone3:'), %q(<img src="/gollum/emoji/point_up_tone3" alt="point_up_tone3" class="emoji">)
    assert_equal filter(':oggy_was_here:'), ':oggy_was_here:'
    assert_equal filter('rake app\:shell:install'), 'rake app:shell:install'
  end
end
