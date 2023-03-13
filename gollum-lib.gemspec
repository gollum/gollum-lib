require File.join(File.dirname(__FILE__), 'gemspec.rb')
require File.join(File.dirname(__FILE__), 'lib', 'gollum-lib', 'version.rb')
# This file needs to conditionally define the default adapter for MRI and Java, because this is the file that is included from the Gemfile.
# In addition, the default Java adapter needs to be defined in gollum-lib_java.gemspec beause that file is used to *build* the Java gem.
if RUBY_PLATFORM == 'java' then
  default_adapter = ['gollum-rjgit_adapter', '~> 1.0']
else
  default_adapter = ['gollum-rugged_adapter', '~> 2.0']
end
Gem::Specification.new &specification(Gollum::Lib::VERSION, default_adapter)
