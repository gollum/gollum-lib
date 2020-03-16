# Set the default git adapter for use in gollum-lib.gemspec and gollum-lib_java.gemspec

if RUBY_PLATFORM == 'java' then
  DEFAULT_ADAPTER_REQ = ['gollum-rjgit_adapter', '>= 0.5.1', '~> 0.5.1']
else
  DEFAULT_ADAPTER_REQ = ['gollum-rugged_adapter', '>= 0.99.4', '~> 0.99.4']
end