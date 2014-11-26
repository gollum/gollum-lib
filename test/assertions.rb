# ~*~ encoding: utf-8 ~*~
require 'nokogiri'
require 'nokogiri/diff'

def normalize_html(text)
  text.strip!
  text.gsub!(/\s\s+/,' ')
  text.gsub!(/\p{Pi}|\p{Pf}|&amp;quot;/u,'"')
  text.gsub!("\u2026",'...')
  text
end

def assert_html_equal(expected, actual, msg = nil)
  msg = build_message(msg, "? expected to be HTML equivalent to ?.", expected, actual)

  assert_block(msg) do
    expected_doc = Nokogiri::HTML(expected) {|config| config.noblanks}
    actual_doc   = Nokogiri::HTML(actual) {|config| config.noblanks}

    expected_doc.search('//text()').each {|node| node.content = normalize_html node.content}
    actual_doc.search('//text()').each {|node| node.content = normalize_html node.content}

    ignore_changes = {"+" => Regexp.union(/^\s*id=".*"\s*$/), "-" => nil}
    expected_doc.diff(actual_doc) do |change, node|
      if change != ' ' && !node.blank? then
        break unless node.to_html =~ ignore_changes[change]
      end
    end
  end
end

def assert_max_seconds(max_seconds, name = "an operation")
  start = Time.now
  yield
  assert (Time.now - start) < max_seconds, "#{name} took more than #{max_seconds} seconds"
end

