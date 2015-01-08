begin
  require 'kramdown'
rescue Exception
end

if defined?(Kramdown) then

  class Kramdown::Converter::Sections < Kramdown::Converter::Html
    include Gollum::TOC
    def convert(el, indent = -@indent)
      @sections = []
      super
      @sections
    end
    def convert_header(el, indent)
      id = el.attr['id'] ? el.attr['id'] : generate_anchor_name(OpenStruct.new(:content => el.options[:raw_text], :name => el.options[:level].to_s))
      @sections << {:id => id, :location => el.options[:location], :level => el.options[:level]} if id
      super
    end
  end

  class Kramdown::SectionSplitter < Kramdown::Document
    def initialize(source, options = {})
      @source = source
      super
    end

    def get_sections
      sections = Kramdown::Converter::Sections.convert(@root, @options).first
      return [] if sections.empty?
      source = @source.lines.to_a
      result = []
      sections.each_with_index do |section, i|
        line = section[:location]
        if sections[i+1] && next_section = sections[i+1][:location]
          result << OpenStruct.new(:id => section[:id], :level => section[:level], :content => source[line-1..next_section-2].join)
        else
          result << OpenStruct.new(:id => section[:id], :level => section[:level], :content => source[line-1..-1].join)
        end
      end
      result.unshift OpenStruct.new(:id => nil, :content => source[0..sections[0][:location]-2].join) if sections[0][:location] > 1
      result
    end
  end

  module Gollum
    class Page
      def find_section_for_edit(header)
        return nil if header.nil?
        sections = Kramdown::SectionSplitter.new(text_data).get_sections
        result_index = sections.find_index {|s| s.id == header}
        return nil unless result_index
        edit = sections[result_index].content
        unless sections[result_index].level == 3
          if last_subsection = sections[result_index+1..-1].find_index {|s| s.level <= sections[result_index].level}
            last_subsection += result_index
          else
            last_subsection = sections.length-1
          end
          append = sections.slice!(result_index+1..last_subsection)
          append.each {|s| edit << s.content} if append
        end
        sections.map! {|s| s.content}
        pre = result_index == 0 ? "" : sections[0..result_index-1].join
        post = sections[result_index+1..-1].join
        return edit, pre, post
      end
    end
  end

end