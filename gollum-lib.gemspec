Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '0.0.1'
  s.required_ruby_version = '>= 1.9'

  s.name              = 'gollum-lib'
  s.version           = '4.0.2'
  s.date              = '2015-01-19'
  s.rubyforge_project = 'gollum-lib'
  s.license           = 'MIT'

  s.summary     = 'A simple, Git-powered wiki.'
  s.description = 'A simple, Git-powered wiki with a sweet API and local frontend.'

  s.authors  = ['Tom Preston-Werner', 'Rick Olson']
  s.email    = 'tom@github.com'
  s.homepage = 'http://github.com/gollum/gollum-lib'

  s.require_paths = %w[lib]

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency 'gollum-grit_adapter', '~> 1.0'
  s.add_dependency 'rouge', '~> 1.7.4'
  s.add_dependency 'nokogiri', '~> 1.6.4'
  s.add_dependency 'stringex', '~> 2.5.1'
  s.add_dependency 'sanitize', '~> 2.1.0'
  s.add_dependency 'github-markup', '~> 1.3.3'

  s.add_development_dependency 'org-ruby', '~> 0.9.9'
  s.add_development_dependency 'github-markdown', '~> 0.6.7'
  s.add_development_dependency 'RedCloth', '~> 4.2.9'
  s.add_development_dependency 'mocha', '~> 1.1.0'
  s.add_development_dependency 'shoulda', '~> 3.5.0'
  s.add_development_dependency 'wikicloth', '~> 0.8.1'
  s.add_development_dependency 'rake', '~> 10.4.0'
  s.add_development_dependency 'pry', '~> 0.10.1'
  # required by pry
  s.add_development_dependency 'rb-readline', '~> 0.5.1'
  # updating minitest-reporters requires a new minitest which fails with gollum's tests.
  s.add_development_dependency 'minitest-reporters', '~> 0.14.16'
  s.add_development_dependency 'nokogiri-diff', '~> 0.2.0'
  # required by guard
  s.add_development_dependency 'guard', '~> 2.8.2'
  s.add_development_dependency 'guard-minitest', '~> 2.3.2'
  s.add_development_dependency 'rb-inotify', '~> 0.9.3'
  s.add_development_dependency 'rb-fsevent', '~> 0.9.4'
  s.add_development_dependency 'rb-fchange', '~> 0.0.6'
  s.add_development_dependency 'twitter_cldr', '~> 3.1.0'
  # = MANIFEST =
  s.files = %w[
    Gemfile
    HISTORY.md
    LICENSE
    README.md
    Rakefile
    docs/sanitization.md
    gollum-lib.gemspec
    lib/gollum-lib.rb
    lib/gollum-lib/blob_entry.rb
    lib/gollum-lib/committer.rb
    lib/gollum-lib/file.rb
    lib/gollum-lib/file_view.rb
    lib/gollum-lib/filter.rb
    lib/gollum-lib/filter/code.rb
    lib/gollum-lib/filter/macro.rb
    lib/gollum-lib/filter/metadata.rb
    lib/gollum-lib/filter/plain_text.rb
    lib/gollum-lib/filter/remote_code.rb
    lib/gollum-lib/filter/render.rb
    lib/gollum-lib/filter/sanitize.rb
    lib/gollum-lib/filter/tags.rb
    lib/gollum-lib/filter/toc.rb
    lib/gollum-lib/filter/wsd.rb
    lib/gollum-lib/git_access.rb
    lib/gollum-lib/gitcode.rb
    lib/gollum-lib/helpers.rb
    lib/gollum-lib/hook.rb
    lib/gollum-lib/macro.rb
    lib/gollum-lib/macro/all_pages.rb
    lib/gollum-lib/markup.rb
    lib/gollum-lib/markups.rb
    lib/gollum-lib/page.rb
    lib/gollum-lib/pagination.rb
    lib/gollum-lib/sanitization.rb
    lib/gollum-lib/wiki.rb
    licenses/licenses.txt
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
