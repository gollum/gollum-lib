def specification(version, default_adapter, platform = nil)
  Proc.new do |s|
    s.specification_version = 2 if s.respond_to? :specification_version=
    s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
    s.rubygems_version = '0.0.1'
    s.required_ruby_version = '>= 2.4'

    s.name              = 'gollum-lib'
    s.version           = version
    s.platform          = platform if platform
    s.date              = '2020-09-23'
    s.date              = '2017-04-13'
    s.rubyforge_project = 'gollum-lib'
    s.license           = 'MIT'

    s.summary     = 'A simple, Git-powered wiki.'
    s.description = 'A simple, Git-powered wiki with a sweet API and local frontend.'

    s.authors  = ['Tom Preston-Werner', 'Rick Olson']
    s.email    = 'tom@github.com'
    s.homepage = 'http://github.com/gollum/gollum-lib'

    s.require_paths = %w(lib)

    s.rdoc_options = ['--charset=UTF-8']
    s.extra_rdoc_files = %w(README.md LICENSE)

    s.add_dependency *default_adapter
    s.add_dependency 'rouge', '~> 3.1'
    s.add_dependency 'nokogiri', '~> 1.8'
    s.add_dependency 'loofah', '~> 2.3'
    s.add_dependency 'github-markup', '~> 3.0'
    s.add_dependency 'gemojione', '~> 4.1'
    s.add_dependency 'octicons', '~> 8.5'
    s.add_dependency 'twitter-text', '1.14.7'

    s.add_development_dependency 'org-ruby', '~> 0.9.9'
    s.add_development_dependency 'kramdown', '~> 2.3.0'
    s.add_development_dependency 'kramdown-parser-gfm', '~> 1.1.0'
    s.add_development_dependency 'RedCloth', '~> 4.3'
    s.add_development_dependency 'mocha', '~> 1.11'
    s.add_development_dependency 'shoulda', '~> 4.0'
    s.add_development_dependency 'wikicloth', '~> 0.8.3'
    s.add_development_dependency 'bibtex-ruby', '~> 4.3'
    s.add_development_dependency 'citeproc-ruby', '~> 1.1'
    s.add_development_dependency 'unicode_utils', '~> 1.4.0' # required by citeproc-ruby on ruby < 2.4
    s.add_development_dependency 'rake', '~> 13.0'
    s.add_development_dependency 'pry', '~> 0.13'
    # required by pry
    s.add_development_dependency 'rb-readline', '~> 0.5.1'
    # updating minitest-reporters requires a new minitest which fails with gollum's tests.
    s.add_development_dependency 'test-unit', '~> 3.3'
    s.add_development_dependency 'minitest-reporters', '~> 1.4'
    s.add_development_dependency 'nokogiri-diff', '~> 0.2.0'
    s.add_development_dependency 'guard', '~> 2.16'
    s.add_development_dependency 'guard-minitest', '~> 2.4'
    s.add_development_dependency 'twitter_cldr', '~> 6.4'
    
    # = MANIFEST =
  s.files = %w(
    Gemfile
    HISTORY.md
    LICENSE
    README.md
    Rakefile
    docs/sanitization.md
    gemspec.rb
    gollum-lib.gemspec
    gollum-lib_java.gemspec
    lib/gollum-lib.rb
    lib/gollum-lib/blob_entry.rb
    lib/gollum-lib/committer.rb
    lib/gollum-lib/file.rb
    lib/gollum-lib/file_view.rb
    lib/gollum-lib/filter.rb
    lib/gollum-lib/filter/bibtex.rb
    lib/gollum-lib/filter/code.rb
    lib/gollum-lib/filter/critic_markup.rb
    lib/gollum-lib/filter/emoji.rb
    lib/gollum-lib/filter/macro.rb
    lib/gollum-lib/filter/pandoc_bib.rb
    lib/gollum-lib/filter/plain_text.rb
    lib/gollum-lib/filter/plantuml.rb
    lib/gollum-lib/filter/remote_code.rb
    lib/gollum-lib/filter/render.rb
    lib/gollum-lib/filter/sanitize.rb
    lib/gollum-lib/filter/tags.rb
    lib/gollum-lib/filter/toc.rb
    lib/gollum-lib/filter/yaml.rb
    lib/gollum-lib/git_access.rb
    lib/gollum-lib/helpers.rb
    lib/gollum-lib/hook.rb
    lib/gollum-lib/macro.rb
    lib/gollum-lib/macro/all_pages.rb
    lib/gollum-lib/macro/audio.rb
    lib/gollum-lib/macro/global_toc.rb
    lib/gollum-lib/macro/navigation.rb
    lib/gollum-lib/macro/note.rb
    lib/gollum-lib/macro/octicon.rb
    lib/gollum-lib/macro/series.rb
    lib/gollum-lib/macro/video.rb
    lib/gollum-lib/macro/warn.rb
    lib/gollum-lib/markup.rb
    lib/gollum-lib/markups.rb
    lib/gollum-lib/page.rb
    lib/gollum-lib/pagination.rb
    lib/gollum-lib/redirects.rb
    lib/gollum-lib/sanitization.rb
    lib/gollum-lib/version.rb
    lib/gollum-lib/wiki.rb
    licenses/licenses.txt
  )
  # = MANIFEST =

    s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
  end
end
