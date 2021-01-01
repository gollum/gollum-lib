gollum lib -- A wiki built on top of Git
========================================

[![Gem Version](https://badge.fury.io/rb/gollum-lib.svg)](http://badge.fury.io/rb/gollum-lib)
[![Build Status](https://travis-ci.org/gollum/gollum-lib.svg?branch=master)](https://travis-ci.org/gollum/gollum-lib)
[![Cutting Edge Dependency Status](https://dometto-cuttingedge.herokuapp.com/github/gollum/gollum-lib/svg 'Cutting Edge Dependency Status')](https://dometto-cuttingedge.herokuapp.com/github/gollum/gollum-lib/info)

## DESCRIPTION

[Gollum](https://github.com/gollum/gollum) is a simple wiki system built on
top of Git that powers GitHub Wikis.

Gollum-lib is the Ruby API that allows you to retrieve raw or formatted wiki
content from a Git repository, write new content to the repository, and collect
various meta data about the wiki as a whole.

Gollum-lib follows the rules of [Semantic Versioning](http://semver.org/) and uses
[TomDoc](http://tomdoc.org/) for inline documentation.

## SYSTEM REQUIREMENTS

- Ruby 2.4.0+
- Unix like operating system (OS X, Ubuntu, Debian, and more)
- Will not work on Windows with the default [rugged](https://github.com/github/grit) adapter, but works via JRuby.

## INSTALLATION

The best way to install Gollum-lib is with RubyGems:

```bash
$ [sudo] gem install gollum-lib
```

If you're installing from source, you can use [Bundler][bundler] to pick up all the
gems:

```bash
$ bundle install
```

In order to use the various formats that Gollum supports, you will need to
separately install the necessary dependencies for each format. You only need
to install the dependencies for the formats that you plan to use.

* [AsciiDoc](http://www.methods.co.nz/asciidoc/) -- `gem install asciidoctor`
* [Creole](http://wikicreole.org/) -- `gem install creole`
* [Markdown](http://daringfireball.net/projects/markdown/) -- `gem install redcarpet`
* [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown) -- `gem install github-markdown`
* [Org](http://orgmode.org/) -- `gem install org-ruby`
* [Pod](http://search.cpan.org/dist/perl/pod/perlpod.pod) -- `Pod::Simple::HTML` comes with Perl >= 5.10. Lower versions should install Pod::Simple from CPAN.
* [RDoc](http://rdoc.sourceforge.net/)
* [ReStructuredText](http://docutils.sourceforge.net/rst.html) -- `easy_install docutils`
* [Textile](http://www.textism.com/tools/textile/) -- `gem install RedCloth`
* [MediaWiki](http://www.mediawiki.org/wiki/Help:Formatting) -- `gem install wikicloth`

[bundler]: http://gembundler.com/

## SYNTAX

Gollum supports a variety of formats and extensions (Markdown, MediaWiki, Textile, …).
On top of these formats Gollum lets you insert headers, footers, links, image, math and more.

Check out the [Gollum Wiki](https://github.com/gollum/gollum/wiki) for all of Gollum's formats and syntactic options.

## API DOCUMENTATION

Initialize the `Gollum::Repo` object:

```ruby
# Require rubygems if necessary
require 'rubygems'

# Require the Gollum library
require 'gollum-lib'

# Create a new Gollum::Wiki object by initializing it with the path to the
# Git repository.
wiki = Gollum::Wiki.new("my-gollum-repo.git")
# => <Gollum::Wiki>
```

By default, internal wiki links are all absolute from the root. To specify a different
base path, you can specify the `:base_path` option:

```ruby
wiki = Gollum::Wiki.new("my-gollum-repo.git", :base_path => "/wiki")
```

Note that `base_path` just modifies the links.

Get the latest version of the given human or canonical page name:

```ruby
page = wiki.page('/page name') # Finds pages in the root directory of the wiki that are named 'page name' with a valid extension.
# => <Gollum::Page>

page = wiki.page('page name') # For convenience, you can leave out the '/' in front. Paths are assumed to be relative to '/'.
# => <Gollum::Page>

page = wiki.page('page name.md') # You can also specifiy the extension explicitly to disambiguate between pages with the same name, but different formats.
# => <Gollum::Page>

page.raw_data
# => "# My wiki page"

page.formatted_data
# => "<h1>My wiki page</h1>"

page.format
# => :markdown

vsn = page.version
# => <Gollum::Git::Commit>

vsn.id
# => '3ca43e12377ea1e32ea5c9ce5992ec8bf266e3e5'
```

Get the footer (if any) for a given page:

```ruby
page.footer
# => <Gollum::Page>
```

Get the header (if any) for a given page:

```ruby
page.header
# => <Gollum::Page>
```

Get a list of versions for a given page:

```ruby
vsns = wiki.page('page-name').versions
# => [<Gollum::Git::Commit, <Gollum::Git::Commit, <Gollum::Git::Commit>]

vsns.first.id
# => '3ca43e12377ea1e32ea5c9ce5992ec8bf266e3e5'

vsns.first.authored_date
# => Sun Mar 28 19:11:21 -0700 2010
```

Get a specific version of a given canonical page file:

```ruby
wiki.page('page name', '5ec521178e0eec4dc39741a8978a2ba6616d0f0a')
```

Get the latest version of a given static file:

```ruby
file = wiki.file('asset.js')
# => <Gollum::File>

file.raw_data
# => "alert('hello');"

file.version
# => <Gollum::Git::Commit>
```

Get a specific version of a given static file:

```ruby
wiki.file('asset.js', '5ec521178e0eec4dc39741a8978a2ba6616d0f0a')
```

Get an in-memory Page preview (useful for generating previews for web
interfaces):

```ruby
preview = wiki.preview_page("My Page", "# Contents", :markdown)
preview.formatted_data
# => "<h1>Contents</h1>"
```

Methods that write to the repository require a Hash of commit data that takes
the following form:

```ruby
commit = { :message => 'commit message',
           :name => 'Tom Preston-Werner',
           :email => 'tom@github.com' }
```

Write a new version of a page (the file will be created if it does not already
exist) and commit the change. The file will be written at the repo root if no subdirectory is specified.

```ruby
wiki.write_page('Subdirectory/Page Name', :markdown, 'Page contents', commit)
```

Update an existing page. If the format is different than the page's current
format, the file name will be changed to reflect the new format.

```ruby
page = wiki.page('Page Name')
wiki.update_page(page, page.name, page.format, 'Page contents', commit)
```

To delete a page and commit the change:

```ruby
wiki.delete_page(page, commit)
```

Register or unregister a hook to be called after a page commit:

```ruby
Gollum::Hook.register(:post_commit, :hook_id) do |committer, sha1|
  # Your code here
end

Gollum::Hook.unregister(:post_commit, :hook_id)
```

Register or unregister a hook to be called after the wiki is initialized:

```ruby
Gollum::Hook.register(:post_wiki_initialize, :hook_id) do |wiki|
  # Your code here
end

Gollum::Hook.unregister(:post_wiki_initialize, :hook_id)
```

A combination of both hooks can be used to pull from a remote after
`:post_wiki_initialize` and push to a remote after `:post_commit` which in
effect keeps the remote in sync both ways. Keep in mind that it may not be
possible to resolve all conflicts automatically.

## WINDOWS FILENAME VALIDATION

Note that filenames on windows must not contain any of the following characters `\ / : * ? " < > |`. See [this support article](http://support.microsoft.com/kb/177506) for details.

## CONTRIBUTE

If you'd like to hack on Gollum-lib, start by forking the repo on GitHub:

http://github.com/gollum/gollum-lib

To get all of the dependencies, install the gem first. The best way to get
your changes merged back into core is as follows:

1. Clone down your fork
1. Create a thoughtfully named topic branch to contain your change
1. Hack away
1. Add tests and make sure everything still passes by running `rake`
1. If you are adding new functionality, document it in the README
1. Do not change the version number, I will do that on my end
1. If necessary, rebase your commits into logical chunks, without errors
1. Push the branch up to GitHub
1. Send a pull request to the gollum/gollum-lib project.

## RELEASING

Gollum-lib uses [Semantic Versioning](http://semver.org/). Having `x.y.z` :

For z releases:

```bash
$ rake bump
$ rake release
```

For x.y releases:

```bash
$ rake gemspec
$ rake release
```

## BUILDING THE GEM FROM MASTER

```bash
$ gem uninstall -aIx gollum-lib
$ git clone https://github.com/gollum/gollum-lib.git
$ cd gollum-lib
gollum-lib$ rake build
gollum-lib$ rake install
```

## RUN THE TESTS

```bash
$ bundle install
$ bundle exec rake test
```

## WORK WITH TEST REPOS

An example of how to add a test file to the bare repository `lotr.git`.

```bash
$ mkdir tmp; cd tmp
$ git clone ../lotr.git/ .
Cloning into '.'...
done.
$ git log
$ echo "test" > test.md
$ git add . ; git commit -am "Add test"
$ git push ../lotr.git/ master
```
