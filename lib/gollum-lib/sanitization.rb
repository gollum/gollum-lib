::Loofah::HTML5::SafeList::ACCEPTABLE_PROTOCOLS.add('apt')

module Gollum
  class Sanitization

    @@accepted_protocols = ::Loofah::HTML5::SafeList::ACCEPTABLE_PROTOCOLS.to_a.freeze

    # This class method is used in the Tag filter to determine whether a link has an acceptable URI scheme.
    def self.accepted_protocols
      @@accepted_protocols
    end

    REMOVE_NODES = ['style', 'script']

    SCRUB_REMOVE = Loofah::Scrubber.new do |node|
      node.remove if REMOVE_NODES.include?(node.name)
    end

    attr_reader :id_prefix

    def initialize(to_xml_opts = {})
      @to_xml_opts = to_xml_opts
    end

    def clean(data, historical = false)
      doc = Loofah.fragment(data)
      doc.scrub!(SCRUB_REMOVE)
      doc.scrub!(:strip)
      doc.scrub!(:nofollow) if historical
      doc.scrub!(wiki_id_scrubber) if id_prefix
      doc.to_xml(@to_xml_opts).gsub('<p></p>', '')
    end

    private

    # Returns a Loofah::Scrubber if the `id_prefix` attribute is set, or nil otherwise.
    def wiki_id_scrubber
      @id_scrubber ||= Loofah::Scrubber.new do |node|
        if node.name == 'a' && val = node['href']
          node['href'] = val.gsub(/\A\#(#{id_prefix})?/, '#' + id_prefix) unless node[:class] == 'internal anchorlink' # Don't prefix pure anchor links
        else
          %w(id name).each do |key|
            if (value = node[key])
              node[key] = value.gsub(/\A(#{id_prefix})?/, id_prefix)
            end
          end
        end
      end
    end

  end
end