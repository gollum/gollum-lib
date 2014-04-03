# ~*~ encoding: utf-8 ~*~
require 'nokogiri'
require 'nokogiri/diff'

def normal(text)
  text.gsub(' ', '').gsub("\n", '')
end

def assert_html_equal(expected, actual, msg = nil)
  msg = build_message(msg, "? expected to be HTML equivalent to ?.", expected, actual)

  expected = normal expected
  actual = normal actual

  assert_block(msg) do
    expected_doc = Nokogiri::HTML(expected) { |config| config.noblanks }
    actual_doc   = Nokogiri::HTML(actual) { |config| config.noblanks }
    # Sometimes there's an extra newline even though the HTML is the same
    # Ignore changes of blank nodes.
    expected_doc.diff(actual_doc) do |change, node|
      break if change != ' ' && !node.blank?
    end
  end
end
