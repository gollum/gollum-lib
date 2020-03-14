# ~*~ encoding: utf-8 ~*~

class Gollum::Filter::Sanitize < Gollum::Filter
  def extract(data)
    data
  end

  def process(data)
    sanitize(data)
  end
end
