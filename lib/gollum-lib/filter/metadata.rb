# Extract metadata for data and build metadata table.  Metadata consists of
# key/value pairs in "key:value" format found between markers.  Each
# key/value pair must be on its own line.  Internal whitespace in keys and
# values is preserved, but external whitespace is ignored.
#
# Because ri and ruby 1.8.7 are awesome, the markers can't
# be included in this documentation without triggering
# `Unhandled special: Special: type=17`
# Please read the source code for the exact markers
class Gollum::Filter::Metadata < Gollum::Filter
  def extract(data)
    # The markers are `<!-- ---` and `-->`
    data.gsub(/\<\!--+\s+---(.*?)--+\>/m) do
      @markup.metadata ||= {}
      # Split untrusted input on newlines, then remove bits that look like
      # HTML elements before parsing each line.
      $1.split("\n").each do |line|
        line.gsub!(/<[^>]*>/, '')
        k, v                      = line.split(':', 2)
        @markup.metadata[k.strip] = (v ? v.strip : '') if k
      end
      ''
    end
  end

  def process(d)
    d
  end
end
