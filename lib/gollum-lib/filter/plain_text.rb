# ~*~ encoding: utf-8 ~*~

# Plain Text
#
# Render plain text documents in a <pre> block without any special markup.

class Gollum::Filter::PlainText < Gollum::Filter

    def do_process(_d)
      skip? ? _d : process(_d)
    end

  def extract(data)
    @markup.format == :txt ? "<pre>#{CGI.escapeHTML(data)}</pre>" : data
  end

  def process(data)
    data
  end
end