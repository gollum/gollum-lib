source 'https://rubygems.org'
gemspec :name => 'gollum-lib'
gem 'irb'

if RUBY_PLATFORM == 'java'
  gem 'gollum-rjgit_adapter', git: 'https://github.com/dometto/gollum-lib_rjgit_adapter/', branch: 'find_branch'
else
  gem 'gollum-rugged_adapter', git: 'https://github.com/gollum/rugged_adapter/', branch: 'find_branches'
end
