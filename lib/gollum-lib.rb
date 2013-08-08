# ~*~ encoding: utf-8 ~*~
# stdlib
require 'digest/md5'
require 'digest/sha1'
require 'ostruct'

# external
require 'grit'
require File.expand_path('../gollum-lib/grit_ext', __FILE__)
require 'github/markup'
require 'sanitize'

# internal
require File.expand_path('../gollum-lib/git_access', __FILE__)
require File.expand_path('../gollum-lib/committer', __FILE__)
require File.expand_path('../gollum-lib/pagination', __FILE__)
require File.expand_path('../gollum-lib/blob_entry', __FILE__)
require File.expand_path('../gollum-lib/wiki', __FILE__)
require File.expand_path('../gollum-lib/page', __FILE__)
require File.expand_path('../gollum-lib/file', __FILE__)
require File.expand_path('../gollum-lib/file_view', __FILE__)
require File.expand_path('../gollum-lib/markup', __FILE__)
require File.expand_path('../gollum-lib/markups', __FILE__)
require File.expand_path('../gollum-lib/sanitization', __FILE__)
require File.expand_path('../gollum-lib/web_sequence_diagram', __FILE__)

# Set ruby to UTF-8 mode
# This is required for Ruby 1.8.7 which gollum still supports.
$KCODE = 'U' if RUBY_VERSION[0,3] == '1.8'

module Gollum
  module Lib
    VERSION = '1.0.4'
  end

  def self.assets_path
    ::File.expand_path('gollum/frontend/public', ::File.dirname(__FILE__))
  end
  
  def self.set_git_timeout(time)
    Grit::Git.git_timeout = time
  end
  
  def self.set_git_max_filesize(size)
    Grit::Git.git_max_size = size
  end

  class Error < StandardError; end

  class DuplicatePageError < Error
    attr_accessor :dir
    attr_accessor :existing_path
    attr_accessor :attempted_path

    def initialize(dir, existing, attempted, message = nil)
      @dir            = dir
      @existing_path  = existing
      @attempted_path = attempted
      super(message || "Cannot write #{@dir}/#{@attempted_path}, found #{@dir}/#{@existing_path}.")
    end
  end
  
  class InvalidGitRepositoryError < StandardError ; end
  class NoSuchPathError < StandardError ; end
  
end

