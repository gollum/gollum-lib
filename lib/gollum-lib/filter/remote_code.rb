# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'net/https' # ruby 1.8.7 fix, remove at upgrade
require 'uri'
require 'open-uri'

# Remote code - fetch code from url and replace the contents to a
#               code-block that gets run the next parse.
#           Acceptable formats:
#              ```language:local-file.ext```
#              ```language:/abs/other-file.ext```
#              ```language:https://example.com/somefile.txt```
#
#           Optionally you can include only a subset of lines by prefixing the url
#           with a range in square quotes.
#
#           Example:
#              ```language:10-20:local-file.ext```
#              ```language:12-:/abs/other-file.ext```
#              ```language:-23:https://example.com/somefile.txt```
#
class Gollum::Filter::RemoteCode < Gollum::Filter
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/^[ \t]*``` ?([^:\n\r]+):(([0-9]+)?-([0-9]+)?:)?((https?)?[^`\n\r]+)```/) do
      language    = Regexp.last_match[1]
      range       = Regexp.last_match[2]
      range_start = Regexp.last_match[3]
      range_end   = Regexp.last_match[4]
      uri         = Regexp.last_match[5]
      protocol    = Regexp.last_match[6]

      contents = fetch(protocol, uri)
      if (!range.nil?) then
          lines       = contents.lines
          range_start = range_start.nil? ? 0              : (range_start.to_i - 1)
          range_end   = range_end.nil?   ? lines.size - 1 : (range_end.to_i   - 1)
          print "#{range_start} .. #{range_end}\n"
          contents    = lines.slice(range_start..range_end).join
      end

      "```#{language}\n#{contents}\n```\n"
    end
  end

  def process(data)
    data
  end

  private

  def fetch(protocol, uri)
      # Detect local file
      if protocol.nil?
        if (file = @markup.find_file(uri, @markup.wiki.ref))
          file.raw_data
        else
          # How do we communicate a render error?
          html_error("File not found: '#{CGI::escapeHTML(uri)}'")
        end
      else
        req(uri)
      end
  end

  def req(uri, cut = 1)
    uri = URI(uri)
    return "Too many redirects or retries" if cut >= 10
    http         = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    resp         = http.get uri.path, {
        'Accept'        => 'text/plain',
        'Cache-Control' => 'no-cache',
        'Connection'    => 'keep-alive',
        'User-Agent'    => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0'
    }
    code         = resp.code.to_i
    return resp.body if code == 200
    return "Not Found" if code == 404
    return "Unhandled Response Code #{code}" unless code == 304 or not resp.header['location'].nil?
    loc  = URI.parse resp.header['location']
    uri2 = loc.relative? ? (uri + loc) : loc # overloads (+)
    req uri2, (cut + 1)
  end
end
