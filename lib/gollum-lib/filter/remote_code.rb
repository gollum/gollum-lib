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
class Gollum::Filter::RemoteCode < Gollum::Filter
  def extract data
    data.gsub /^[ \t]*``` ?([^:\n\r]+):((http)?[^`\n\r]+)```/ do
      language = $1
      uri = $2
      protocol = $3

      # Detect local file
      if protocol.nil?
        if file = @markup.find_file(uri, @markup.wiki.ref)
          contents = file.raw_data
        else
          # How do we communicate a render error?
          next html_error("File not found: #{CGI::escapeHTML(uri)}")
        end
      else
        contents = req(uri)
      end

      "```#{language}\n#{contents}\n```\n"
    end
  end
  
  def process(d) d; end

  private

    def req uri, cut = 1
      uri = URI(uri)
      return "Too many redirects or retries" if cut >= 10
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      resp = http.get uri.path, {
        'Accept'        => 'text/plain',
        'Cache-Control' => 'no-cache',
        'Connection'    => 'keep-alive',
        'User-Agent'    => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0'
      }
      code = resp.code.to_i
      return resp.body if code == 200
      return "Not Found" if code == 404
      return "Unhandled Response Code #{code}" unless code == 304 or not resp.header['location'].nil?
      loc = URI.parse resp.header['location']
      uri2 = loc.relative? ? (uri + loc) : loc # overloads (+)
      req uri2, (cut + 1)
    end
end
