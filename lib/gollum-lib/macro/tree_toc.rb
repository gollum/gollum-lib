module Gollum
  class Macro
    class TreeTOC < Gollum::Macro
      def render(title = "Global Table of Contents")
        def add_leaf_to_tree(leaf, tree, full_path = nil)
          full_path ||= leaf
          fname = ::File.basename leaf
          fdir  = ::File.dirname  leaf
          
          if fdir.include?('/')
            base_dir, sub_path = leaf.split '/', 2
            tree[base_dir] ||= {}
            add_leaf_to_tree sub_path, tree[base_dir], full_path
          else
            if fdir == '.'
              tree[:leafs] ||= []
              tree[:leafs] << {lbl: fname, fp: full_path}
            else
              tree[fdir] ||= {}
              tree[fdir][:leafs] ||= []
              tree[fdir][:leafs] << {lbl: fname, fp: full_path}
            end
          end
          
          tree
        end # add_leaf_to_tree -------------------------------------------------
        
        def tree_to_html(tree, prepath)
          result = '<ul>'
          tree.each do |dir, data|
            if dir == :leafs
              data.each{|d| result.concat %Q|<li><a href="#{prepath}/#{::ERB::Util.url_encode d[:fp]}">#{d[:lbl]}</a></li>| }
            else
              result.concat %Q|<li class="folder">#{dir}/|
              result.concat tree_to_html(data, prepath)
              result.concat '</li>'
            end
          end
          result.concat '</ul>'
        end # tree_to_html -----------------------------------------------------

        # build a Hash tree from the pages list
        tree = {}
        @wiki.pages.each{|p| add_leaf_to_tree p.url_path, tree }
        
        # build cascading UL from the Hash tree
        tree_html = tree_to_html tree, @wiki.base_path.sub(/\/$/, '')
        
        %Q|<div class="toc tree-toc"><div class="toc-title">#{title}</div>#{tree_html}</div>|
      end # render
    end # class TreeTOC
  end # class Macro
end # module Gollum
