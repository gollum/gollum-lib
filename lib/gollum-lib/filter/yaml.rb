require 'yaml'
# Extract YAML frontmatter from data and build metadata table. 

class Gollum::Filter::YAML < Gollum::Filter
  
  # Regexp thanks to jekyll
  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m

  def extract(data)
    data.gsub!(YAML_FRONT_MATTER_REGEXP) do
      @markup.metadata ||= {}
      begin
        frontmatter = sanitize_frontmatter(::YAML.safe_load(Regexp.last_match[1]))
        @markup.metadata.merge!(frontmatter) if frontmatter.respond_to?(:keys) && frontmatter.respond_to?(:values)
      rescue ::Psych::SyntaxError, ::Psych::DisallowedClass, ::Psych::BadAlias => error
        @markup.metadata['errors'] ||= []
        @markup.metadata['errors'] << "Failed to load YAML frontmatter: #{error.message}"
      end
      ''
    end
    data
  end

  def process(data)
    data
  end

  private

  def sanitize_frontmatter(obj)
    case obj
    when Hash
      obj.map do |k, v|
        [sanitize(k.to_s), sanitize_frontmatter(v)]
      end.to_h
    when Array
      obj.map! do |v|
        sanitize_frontmatter(v)
      end
    when String
      sanitize(obj)
    else
      obj
    end
  end
end
