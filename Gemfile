source 'https://rubygems.org'

if RUBY_PLATFORM == 'java'
  gem 'gollum-rjgit_adapter', :git => 'https://github.com/repotag/gollum-lib_rjgit_adapter' # For development purposes
else
  gem 'gollum-rugged_adapter', :git => 'https://github.com/dometto/rugged_adapter.git', :branch => 'refactor_grep' # For development purposes
end

gemspec :name => 'gollum-lib'
