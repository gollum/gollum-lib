Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '0.0.1'
  s.required_ruby_version = ">= 1.9"

  s.name              = 'gollum-lib'
  s.version           = '1.0.9'
  s.date              = '2013-11-02'
  s.rubyforge_project = 'gollum-lib'
  s.license           = 'MIT'

  s.summary     = "A simple, Git-powered wiki."
  s.description = "A simple, Git-powered wiki with a sweet API and local frontend."

  s.authors  = ["Tom Preston-Werner", "Rick Olson"]
  s.email    = 'tom@github.com'
  s.homepage = 'http://github.com/gollum/gollum-lib'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('gitlab-grit', '2.6.0')
  s.add_dependency('github-markup', ['>= 0.7.5', '< 1.0.0'])
  s.add_dependency('pygments.rb', '~> 0.5.2')
  s.add_dependency('sanitize', '~> 2.0.6')
  s.add_dependency('nokogiri', '~> 1.6.0')
  s.add_dependency('stringex', '~> 2.1.0')

  s.add_development_dependency('github-markdown', '~> 0.5.3')
  s.add_development_dependency('RedCloth', '~> 4.2.9')
  s.add_development_dependency('mocha', '~> 0.13.2')
  s.add_development_dependency('org-ruby', '~> 0.8.1')
  s.add_development_dependency('shoulda', '~> 3.4.0')
  s.add_development_dependency('wikicloth', '~> 0.8.0')
  s.add_development_dependency('rake', '~> 10.0.3')
  s.add_development_dependency('pry', '~> 0.9.12')
  # required by pry
  s.add_development_dependency('rb-readline', '~> 0.4.2')
  s.add_development_dependency 'minitest-reporters', '~> 0.14.16'
  s.add_development_dependency('nokogiri-diff', '~> 0.1.2')
  # required by guard
  s.add_development_dependency('guard', '~> 1.8.0')
  s.add_development_dependency('guard-minitest', '~> 0.5.0')
  s.add_development_dependency('rb-inotify', '~> 0.9.0')
  s.add_development_dependency('rb-fsevent', '~> 0.9.3')
  s.add_development_dependency('rb-fchange', '~> 0.0.6')

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
    lib/gollum-lib/git_access.rb
    lib/gollum-lib/gitcode.rb
    lib/gollum-lib/grit_ext.rb
    lib/gollum-lib/helpers.rb
    lib/gollum-lib/hook.rb
    lib/gollum-lib/markup.rb
    lib/gollum-lib/markups.rb
    lib/gollum-lib/page.rb
    lib/gollum-lib/pagination.rb
    lib/gollum-lib/remote_code.rb
    lib/gollum-lib/sanitization.rb
    lib/gollum-lib/web_sequence_diagram.rb
    lib/gollum-lib/wiki.rb
    licenses/licenses.txt
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
