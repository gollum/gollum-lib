require File.join(File.dirname(__FILE__), 'gemspec.rb')
require File.join(File.dirname(__FILE__), 'lib', 'gollum-lib', 'version.rb')
  if RUBY_PLATFORM == 'java' then
    default_adapter = ['gollum-rjgit_adapter', '~> 0.3']
  else
    default_adapter = ['gollum-grit_adapter', '~> 1.0']
  end
Gem::Specification.new &specification(Gollum::Lib::VERSION, default_adapter)