source 'https://rubygems.org'
gemspec :name => 'gollum-lib'
gem 'irb'

if RUBY_PLATFORM == 'java' then
  gem 'gollum-rugged_adapter', git: 'gollum-lib_rjgit_adapter', branch: 'tree_find_blob'
  group :development do
    gem 'activesupport', '~> 6.0'
  end
else
  gem 'gollum-rugged_adapter', git: 'https://github.com/gollum/rugged_adapter'
end
