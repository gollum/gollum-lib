# ~*~ encoding: utf-8 ~*~

class Gollum::Filter::Render < Gollum::Filter
  def extract(data)
    begin
      format = Gollum::Markup.formats[@markup.format][:name]
      format = "rest" if format == "reStructuredText"
      format = "org" if format == "Org-mode"

      # format is determined from file extension
      data = GitHub::Markup.render("."+format.downcase, data)
      if data.nil?
        raise "There was an error converting #{@markup.name} to HTML."
      end
    rescue Object => e
      data = html_error("Failed to render page: #{e.message}")
    end

    data
  end

  def process(data)
    data
  end
end
