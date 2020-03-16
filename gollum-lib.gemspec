require File.join(File.dirname(__FILE__), 'gemspec.rb')
require File.join(File.dirname(__FILE__), 'adapter_dependencies.rb')
require File.join(File.dirname(__FILE__), 'lib', 'gollum-lib', 'version.rb')
Gem::Specification.new &specification(Gollum::Lib::VERSION, DEFAULT_ADAPTER_REQ)
