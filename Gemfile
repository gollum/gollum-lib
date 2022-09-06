source 'https://rubygems.org'
gemspec :name => 'gollum-lib'
gem 'irb'

# Chaanges to this branch require corresponding changes in the adapters, see https://github.com/gollum/gollum-lib/pull/424
if RUBY_PLATFORM == 'java'
  gem 'gollum-rjgit_adapter', git: 'https://github.com/dometto/gollum-lib_rjgit_adapter/', branch: 'find_branch'
else
  gem 'gollum-rugged_adapter', git: 'https://github.com/gollum/rugged_adapter/', branch: 'find_branches'
end
