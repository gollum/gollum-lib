# ~*~ encoding: utf-8 ~*~
class WikiFactory
  def self.create(p, opt = {})
    path = testpath(p)
    Gollum::Git::Repo.init_bare(path)
    Gollum::Wiki.default_options = { :universal_toc => false }.merge(opt)
    cleanup                      = Proc.new { FileUtils.rm_r File.join(File.dirname(__FILE__), *%w(examples test.git)) }
    wiki                         = Gollum::Wiki.new(path)
    # set 'wiki-' prefix on ids for tests
    wiki.sanitization.id_prefix  = 'wiki-'
    return wiki, path, cleanup
  end
end
