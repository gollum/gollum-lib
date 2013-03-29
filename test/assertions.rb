# ~*~ encoding: utf-8 ~*~
require 'nokogiri'
require 'nokogiri/diff'

def assert_html_equal(expected, actual, msg = nil)
  msg = build_message(msg, "? expected to be HTML equivalent to ?.", expected, actual)
  assert_block(msg) do
    expected_doc = Nokogiri::HTML(expected) { |config| config.noblanks }
    actual_doc   = Nokogiri::HTML(actual) { |config| config.noblanks }
    expected_doc.diff(actual_doc) do |change, node|
      break if change != ' '
    end
  end
end
