module Gollum
  class Macro
    class Video < Gollum::Macro
      def render (fname)
        begin 
          pname = ::File.join(Pathname(@wiki.repo.path).dirname.to_s, fname)
          fd =::File.open (pname)
          rescue Exception => error
            return "<p>!!!File Error: #{error}!!!</p>"
        end      
        vname=  MIME::Types.type_for(pname).first.sub_type  
        fd.close
        "<video width=\"100%\" height=\"100%\" controls> <source src=\"#{fname}\" type=\"video/#{vname}\"> HTML5 video is not supported on this Browser. </source></video>"
      end
    end
  end
end