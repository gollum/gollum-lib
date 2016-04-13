# ~*~ encoding: utf-8 ~*~

# Emoji
#
# Render emoji such as :smile:
class Gollum::Filter::Emoji < Gollum::Filter
  EMOJI_TAG_PATTERN = %r{
    (?<!\[{2})
    :(?:([\w-]|</?em>)+):
    (?!\]{^2})
  }ix

  def extract(data)
    data
  end

  def process(data)
    data.gsub EMOJI_TAG_PATTERN do |tag|
      name = tag[1..-2].gsub(%r{</?em>}, '_')   # undo emphasis
      %Q(<img src="/emoji/#{name}" alt="#{name}" class="emoji">)
    end
  end
end
