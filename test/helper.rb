# ~*~ encoding: utf-8 ~*~

# stdlib
require 'test/unit'
require 'fileutils'

# external
require 'rubygems'
require 'shoulda'
require 'mocha/setup'
require 'minitest/reporters'
require 'twitter_cldr'
require 'tempfile'

# markup
begin
  require 'asciidoctor'
rescue Exception
end

# internal
require File.expand_path('../assertions', __FILE__)

# Fix locale warnings
require 'i18n'
I18n.enforce_available_locales = false

MiniTest::Reporters.use!

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
$LOAD_PATH.unshift(dir)

module Gollum
end
Gollum::GIT_ADAPTER = ENV['GIT_ADAPTER'] if ENV['GIT_ADAPTER']

ENV['RACK_ENV'] = 'test'
require 'gollum-lib'

# Make sure we're in the test dir, the tests expect that to be the current
# directory.
TEST_DIR = File.join(File.dirname(__FILE__), *%w(.))

def testpath(path)
  File.join(TEST_DIR, path)
end

def cloned_testpath(path, bare = false)
  repo   = File.expand_path(testpath(path))
  path   = File.dirname(repo)
  name   = File.basename(Tempfile.new(self.class.name, path).path)
  cloned = File.join(path, name)
  bare   = bare ? "--bare" : ""
  FileUtils.rm_rf(cloned)
  Dir.chdir(path) do
    %x{git clone #{bare} #{File.basename(repo)} #{name} 2>/dev/null}
  end
  cloned
end

def commit_details
  { :message => "Did something at #{Time.now}",
    :name    => "Tom Preston-Werner",
    :email   => "tom@github.com" }
end

class MockWiki
  def file(path)
    OpenStruct.new(
      :sha => 'a35311d46dcd49c2ab63ad9bcbcf16254ac53142',
      :raw_data => 'Very raw data'
    )
  end
end

def mock_page(format = nil, data = nil)
  OpenStruct.new(
      :wiki => MockWiki.new,
      :filename => 'Name.md',
      :text_data => data || "# Title\nData",
      :version => nil,
      :format => format || :markdown,
      :sub_page => false,
      :partent_page => false,
      :path => "Name.md"
    )
end

# test/spec/mini 3
# http://gist.github.com/25455
# chris@ozmm.org
# file:lib/test/spec/mini.rb
def context(*args, &block)
  return super unless (name = args.first) && block
  require 'test/unit'
  klass = Class.new(defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase : Test::Unit::TestCase) do
    def self.test(name, &block)
      define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
    end

    def self.xtest(*args)
    end

    def self.setup(&block)
      define_method(:setup, &block)
    end

    def self.teardown(&block)
      define_method(:teardown, &block)
    end
  end
  (
  class << klass;
    self
  end).send(:define_method, :name) { name.gsub(/\W/, '_') }
  $contexts << klass
  klass.class_eval(&block)
end

$contexts = []
