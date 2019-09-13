# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "..", "helper")
require File.expand_path(path)

context "Gollum::Filter::CriticMarkup" do
  setup do
    @filter = Gollum::Filter::CriticMarkup.new(Gollum::Markup.new(mock_page))
  end

  def filter(content)
    @filter.process(@filter.extract(content))
  end

  # Examples from CriticMarkup spec: http://criticmarkup.com/spec.php

  test "basic addition" do
    assert_equal filter('Lorem ipsum dolor{++ sit++} amet'), 'Lorem ipsum dolor<ins> sit</ins> amet'
  end

  test "paragraph addition" do
    input = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla. Mauris massa sem, tempor sed cursus et, semper tincidunt lacus.{++

++}Praesent sagittis, quam id egestas consequat, nisl orci vehicula libero, quis ultricies nulla magna interdum sem. Maecenas eget orci vitae eros accumsan mollis. Cras mi mi, rutrum id aliquam in, aliquet vitae tellus. Sed neque justo, cursus in commodo eget, facilisis eget nunc. Cras tincidunt auctor varius.'
    expected_output = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla. Mauris massa sem, tempor sed cursus et, semper tincidunt lacus.

<ins class='critic break'>&nbsp;</ins>

Praesent sagittis, quam id egestas consequat, nisl orci vehicula libero, quis ultricies nulla magna interdum sem. Maecenas eget orci vitae eros accumsan mollis. Cras mi mi, rutrum id aliquam in, aliquet vitae tellus. Sed neque justo, cursus in commodo eget, facilisis eget nunc. Cras tincidunt auctor varius."
    assert_equal filter(input), expected_output
  end

  test "basic deletion" do
    assert_equal filter('Lorem {-- ipsum--} dolor sit amet'), 'Lorem <del> ipsum</del> dolor sit amet'
  end

  test "paragraph deletion" do
    input = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla. Mauris massa sem, tempor sed cursus et, semper tincidunt lacus.{--

--}Praesent sagittis, quam id egestas consequat, nisl orci vehicula libero, quis ultricies nulla magna interdum sem. Maecenas eget orci vitae eros accumsan mollis. Cras mi mi, rutrum id aliquam in, aliquet vitae tellus. Sed neque justo, cursus in commodo eget, facilisis eget nunc. Cras tincidunt auctor varius.'
    expected_output = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla. Mauris massa sem, tempor sed cursus et, semper tincidunt lacus.<del>&nbsp;</del>Praesent sagittis, quam id egestas consequat, nisl orci vehicula libero, quis ultricies nulla magna interdum sem. Maecenas eget orci vitae eros accumsan mollis. Cras mi mi, rutrum id aliquam in, aliquet vitae tellus. Sed neque justo, cursus in commodo eget, facilisis eget nunc. Cras tincidunt auctor varius."
    assert_equal filter(input), expected_output
  end

  test "basic substitution" do
    assert_equal filter('Lorem {~~hipsum~>ipsum~~} dolor sit amet'), 'Lorem <del>hipsum</del><ins>ipsum</ins> dolor sit amet'
  end

  test "basic comment" do
    assert_equal filter('Lorem ipsum dolor sit amet.{>>This is a comment<<}'), "Lorem ipsum dolor sit amet.<span class='critic comment'>This is a comment</span>"
  end

  test "basic highlight" do
    input = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. {==Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla.==}{>>confusing<<} Mauris massa sem, tempor sed cursus et, semper tincidunt lacus.'
    expected_output = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. <mark>Vestibulum at orci magna. Phasellus augue justo, sodales eu pulvinar ac, vulputate eget nulla.</mark><span class='critic comment'>confusing</span> Mauris massa sem, tempor sed cursus et, semper tincidunt lacus."
    assert_equal filter(input), expected_output
  end

  test "all together" do
    input = "Don't go around saying{-- to people that--} the world owes you a living. The world owes you nothing. It was here first. {~~One~>Only one~~} thing is impossible for God: To find {++any++} sense in any copyright law on the planet. {==Truth is stranger than fiction==}{>>strange but true<<}, but it is because Fiction is obliged to stick to possibilities; Truth isn't."
    expected_output = "Don't go around saying<del> to people that</del> the world owes you a living. The world owes you nothing. It was here first. <del>One</del><ins>Only one</ins> thing is impossible for God: To find <ins>any</ins> sense in any copyright law on the planet. <mark>Truth is stranger than fiction</mark><span class='critic comment'>strange but true</span>, but it is because Fiction is obliged to stick to possibilities; Truth isn't."
    assert_equal filter(input), expected_output
  end

end
