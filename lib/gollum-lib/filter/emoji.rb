# ~*~ encoding: utf-8 ~*~

# Emoji
#
# Render emoji such as :smile:
class Gollum::Filter::Emoji < Gollum::Filter

  EXTRACT_PATTERN = %r{
    (?<!\[{2})
    :(?<name>[\w-]+):
    (?!\]{^2})
  }ix

  PROCESS_PATTERN = %r{
    =EEMMOOJJII=
    (?<name>[\w-]+)
    =IIJJOOMMEE=
  }ix

  def extract(data)
    data.gsub! EXTRACT_PATTERN do
      emoji_exists?($~[:name]) ? "=EEMMOOJJII=#{$~[:name]}=IIJJOOMMEE=" : $&
    end
    data
  end

  def process(data)
    data.gsub! PROCESS_PATTERN, %q(<img src="/emoji/\k<name>" alt="\k<name>" class="emoji">)
    data
  end

  private

  def emoji_exists?(name)
    @index ||= Gemojione::Index.new
    !!@index.find_by_name(name)
  end

end
