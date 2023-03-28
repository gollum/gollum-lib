source 'https://rubygems.org'
gemspec :name => 'gollum-lib'
gem 'irb'
gem 'gollum-rugged_adapter', git: 'https://github.com/gollum/rugged_adapter'

if RUBY_PLATFORM == 'java' then
  group :development do
    gem 'activesupport', '~> 6.0'
  end
end
