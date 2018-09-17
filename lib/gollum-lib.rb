# ~*~ encoding: utf-8 ~*~
# stdlib
require 'digest/md5'
require 'digest/sha1'
require 'ostruct'
require 'pathname'

DEFAULT_ADAPTER = RUBY_PLATFORM == 'java' ? 'rjgit' : 'grit'

Gollum::GIT_ADAPTER = DEFAULT_ADAPTER if !defined?(Gollum::GIT_ADAPTER)
require "#{Gollum::GIT_ADAPTER.downcase}_adapter"

# external
require 'github/markup'
require 'sanitize'
require 'gemojione'

# internal
require File.expand_path('../gollum-lib/git_access', __FILE__)
require File.expand_path('../gollum-lib/hook', __FILE__)
require File.expand_path('../gollum-lib/committer', __FILE__)
require File.expand_path('../gollum-lib/pagination', __FILE__)
require File.expand_path('../gollum-lib/blob_entry', __FILE__)
require File.expand_path('../gollum-lib/wiki', __FILE__)
require File.expand_path('../gollum-lib/page', __FILE__)
require File.expand_path('../gollum-lib/macro', __FILE__)
require File.expand_path('../gollum-lib/file', __FILE__)
require File.expand_path('../gollum-lib/file_view', __FILE__)
require File.expand_path('../gollum-lib/markup', __FILE__)
require File.expand_path('../gollum-lib/markups', __FILE__)
require File.expand_path('../gollum-lib/sanitization', __FILE__)
require File.expand_path('../gollum-lib/filter', __FILE__)

module Gollum

  def self.assets_path
    ::File.expand_path('gollum/frontend/public', ::File.dirname(__FILE__))
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

  class InvalidGitRepositoryError < StandardError; end
  class NoSuchPathError < StandardError; end

end
