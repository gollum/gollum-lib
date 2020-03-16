require File.join(File.dirname(__FILE__), 'gemspec.rb')
require File.join(File.dirname(__FILE__), 'lib', 'gollum-lib', 'version.rb')
default_adapter = ['gollum-rjgit_adapter', '~> 0.5.1']
Gem::Specification.new &specification(Gollum::Lib::VERSION, default_adapter, "java") 