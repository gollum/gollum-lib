# frozen_string_literal: true

module Gollum
  class Macro
    class StructuredGlobalTOC < Gollum::Macro
      TocPage = Struct.new(:page, :path) do
        def initialize(page:, path: nil)
          super(page, path || page.url_path.split('/'))
        end
      end

      def render(title = "Global Table of Contents")
        @toc_cnt = 0
        if @wiki.pages.size > 0
          result = element(:ul) { page_group_html(page_groups) }
        end
        element :div, class: 'toc', style: 'cursor: pointer' do
            element(:div, class: 'toc-title') { CGI::escapeHTML(title) } +
            result.to_s
        end
      end

      def javascript
        <<~SCRIPT
          document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.toggle-button').forEach(function(button) {
              button.addEventListener('click', function() {
                const targetId = this.dataset.target;
                const targetSection = document.getElementById(targetId);
                if (targetSection.attributes['style'].value == 'display:none;') {
                  targetSection.attributes['style'].value = '';
                  this.textContent = '▾' + this.textContent.substring(1);
                } else {
                  targetSection.attributes['style'].value = 'display:none;';
                  this.textContent = '▸' + this.textContent.substring(1);
                }
              });
            });
          });
        SCRIPT
      end

      private

      def page_group_html(groups, full_path = [])
        groups.map do |path, group|
          if path
            folder_html(path, group, full_path + [path])
          else
            pages_html(group)
          end
        end.join('')
      end

      def folder_html(path, group, full_path)
        active = within?(full_path)
        toggle_txt = active ? "&#9662;\u{2002}" : "&#9656;\u{2002}"
        style = active ? '' : 'display:none;'
        toc_id = "toc_#{@toc_cnt += 1}"
        element :li, style: 'list-style-type: none;' do
          element(:span, class: 'toggle-button',
                  style: 'margin-left: -1em',
                  'data-target': toc_id) {
            toggle_txt + CGI::escapeHTML(capitalize(path))
          } +
            element(:ul, id: toc_id, style: style) {
            page_group_html(group, full_path)
          }
        end
      end

      def pages_html(group)
        group.map do |p|
          element :li, style: 'list-style-type: disc;' do
            element :a, href: prepath + '/' + p.page.escaped_url_path do
              page_name(p.page)
            end
          end
        end.join
      end

      def within?(path)
        active_page.url_path.start_with?(path.join('/'))
      end

      def page_name(page)
        name = capitalize(page.name)
        if name.size > 18
          element :span, title: CGI::escapeHTML(name) do
            CGI::escapeHTML(name[0..17]) + "…"
          end
        else
          CGI::escapeHTML(name)
        end
      end

      def capitalize(text)
        text.split(/[\s_]+/).map { |word| word = word[0].upcase + word[1..] }.join(' ')
      end

      def prepath
        @prepath ||= @wiki.base_path.sub(/\/$/, '')
      end

      def page_groups
        group(@wiki.pages.map { |page| TocPage.new(page: page) })
      end

      def group(pages, offset=0)
        groups = pages.group_by { |page| page.path.size > offset + 1 ? page.path[offset] : nil }
        groups.each do |path, subgroup|
          next unless subgroup.any? { |page| page.path.size > offset + 1 }

          groups[path] = group(subgroup, offset + 1)
        end
        groups.sort_by { |path, _group| path || '' }
      end

      def element(name, attributes = {})
        out = '<' + ([name] + attributes.map {|name, value| "#{name}='#{value}'"}).join(' ')
        if block_given?
          out += '>'
          out += yield
          out += "</#{name}>"
        else
          out += '/>'
        end
        out
      end
    end
  end
end
