# ~*~ encoding: utf-8 ~*~

# Emoji
#
# Render an emoji tag such as ":smile:". In some rare situations, you have
# to escape emoji tags e.g. when your content contains something like
# "hh:mm:ss" or "rake app:shell:install". Prefix the leading colon with a
# backslash to disable this emoji tag e.g. "hh\:mm:ss".
class Gollum::Filter::Emoji < Gollum::Filter

  EXTRACT_PATTERN = %r{
    (?<!\[{2})
    (?<escape>\\)?:(?<name>[\w-]+):
    (?!\]{^2})
  }ix

  def extract(data)
    data.gsub! EXTRACT_PATTERN do
      case
        when $~[:escape] then $&[1..-1]
        when emoji_exists?($~[:name]) then "#{open_pattern}#{$~[:name]}#{close_pattern}"
        else $&
      end
    end
    data
  end

  def process(data)
    data.gsub! process_pattern, %q(<img src="/emoji/\k<name>" alt="\k<name>" class="emoji">)
    data
  end

  private

  def process_pattern
    %r{
    #{open_pattern}
    (?<name>[\w-]+)
    #{close_pattern}
  }ix
  end

  def emoji_exists?(name)
    @index ||= Gemojione::Index.new
    !!@index.find_by_name(name)
  end

end
