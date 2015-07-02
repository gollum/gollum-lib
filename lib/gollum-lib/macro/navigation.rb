
module Gollum
  class Macro
    # Displays a tree of all available pages with links to them.
    #
    # Directories link to their underlying Home page.
    #   e.g. Directory/ -> Directory/Home
    class Navigation < Gollum::Macro

      # Recursively insert page into tree according node_list
      #
      # tree        - Tree of Hash gollum::Pages
      # page        - Current gollum::Page object to add
      # node_list   - Array of nodes from page.path
      def _tree_insert(tree, page, node_list)
        node = node_list.first
        if node_list.length() == 1 then
          tree[node] = page
        else
          tree[node] = Hash.new if tree[node].nil?
          _tree_insert(tree[node], page, node_list[1..node_list.length()-1])
        end
      end

      # Insert page into tree
      #
      # tree        - Empty hash, to be filled with pages
      # page        - Page to add as gollum::Page
      def tree_insert(tree, page)
        node_list = page.path.split("/")
        _tree_insert(tree, page, node_list)
      end

      # Recursively prints the page tree as a list tree
      #
      # tree        - Tree of Hash gollum::Pages
      # folder      - Current folder, start with empty string
      def tree_print(tree, folder)
        str = "";
        tree.each do |key, value|
          if not value.is_a?(Hash)
            # page
            if value.name != "Home"
              str += "<li><a href=\"/#{@wiki.base_path}#{value.url_path}\">#{value.name}</a></li>"
            end
          else
            # folder
            subfolder = folder + "/" + key
            str += "<li><a href=\"#{@wiki.base_path}#{subfolder}/\">#{key}</a>"
            str += "<ul>"
            str += tree_print(value, subfolder)
            str += "</ul>"
            str += "</li>"
          end
        end
        return str
      end

      def render
        tree = Hash.new
        @wiki.pages.map { |p|
          tree_insert(tree, p)
        }
        return "<div class=\"toc-title\">Navigation</div><ul>" + tree_print(tree, "") + "</ul>"
      end
    end
  end
end
