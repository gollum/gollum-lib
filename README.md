gollum lib -- A wiki built on top of Git
========================================

[![Build Status](https://travis-ci.org/gollum/gollum-lib.png)](https://travis-ci.org/gollum/gollum-lib)
[![Dependency Status](https://gemnasium.com/gollum/gollum-lib.png)](https://gemnasium.com/gollum/gollum-lib)

## DESCRIPTION

[Gollum](https://github.com/gollum/gollum) is a simple wiki system built on
top of Git that powers GitHub Wikis.

Gollum-lib is the Ruby API that allows you to retrieve raw or formatted wiki
content from a Git repository, write new content to the repository, and collect
various meta data about the wiki as a whole.

Gollum-lib follows the rules of [Semantic Versioning](http://semver.org/) and uses
[TomDoc](http://tomdoc.org/) for inline documentation.

## SYSTEM REQUIREMENTS

- Python 2.5+ (2.7.3 recommended)
- Ruby 1.8.7+ (1.9.3 recommended)
- Unix like operating system (OS X, Ubuntu, Debian, and more)
- Will not work on Windows (because of [grit](https://github.com/github/grit))

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

* [ASCIIDoc](http://www.methods.co.nz/asciidoc/) -- `brew install asciidoc` on mac or `apt-get install -y asciidoc` on Ubuntu
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

## PAGE FILES

Page files may be written in any format supported by
[GitHub-Markup](http://github.com/github/markup) (except roff). By default,
Gollum recognizes the following extensions:

* ASCIIDoc: .asciidoc
* Creole: .creole
* Markdown: .markdown, .mdown, .mkdn, .mkd, .md
* Org Mode: .org
* Pod: .pod
* RDoc: .rdoc
* ReStructuredText: .rest.txt, .rst.txt, .rest, .rst
* Textile: .textile
* MediaWiki: .mediawiki, .wiki

You may also register your own extensions and parsers:

```ruby
Gollum::Markup.register(:angry, "Angry") do |content|
  content.upcase
end
```

Gollum detects the page file format via the extension, so files must have one
of the default or registered extensions in order to be converted.

Page file names may contain any printable UTF-8 character except space
(U+0020) and forward slash (U+002F). If you commit a page file with any of
these characters in the name it will not be accessible via the web interface.

Even though page files may be placed in any directory, there is still only a
single namespace for page names, so all page files should have globally unique
names regardless of where they are located in the repository.

The special page file `Home.ext` (where the extension is one of the supported
formats) will be used as the entrance page to your wiki. If it is missing, an
automatically generated table of contents will be shown instead.

## SIDEBAR FILES

Sidebar files allow you to add a simple sidebar to your wiki. Sidebar files
are named `_Sidebar.ext` where the extension is one of the supported formats.
Sidebars affect all pages in their directory and any subdirectories that do not
have a sidebar file of their own.

## HEADER FILES

Header files allow you to add a simple header to your wiki. Header files must
be named `_Header.ext` where the extension is one of the supported formats.
Like sidebars, headers affect all pages in their directory and any
subdirectories that do not have a header file of their own.

## FOOTER FILES

Footer files allow you to add a simple footer to your wiki. Footer files must
be named `_Footer.ext` where the extension is one of the supported formats.
Like sidebars, footers affect all pages in their directory and any
subdirectories that do not have a footer file of their own.

## HTML SANITIZATION

For security and compatibility reasons Gollum wikis may not contain custom CSS
or JavaScript. These tags will be stripped from the converted HTML. See
`docs/sanitization.md` for more details on what tags and attributes are
allowed.

## TITLES

The first defined `h1` will override the default header on a page. There are two ways to set a page title. The metadata syntax:

`<!-- --- title: New Title -->`

The first `h1` tag can be set to always override the page title, without needing to use the metadata syntax. Start gollum with the `--h1-title` flag.

## BRACKET TAGS

A variety of Gollum tags use a double bracket syntax. For example:

    [[Link]]

Some tags will accept attributes which are separated by pipe symbols. For
example:

    [[Link|Page Title]]

In all cases, the first thing in the link is what is displayed on the page.
So, if the tag is an internal wiki link, the first thing in the tag will be
the link text displayed on the page. If the tag is an embedded image, the
first thing in the tag will be a path to an image file. Use this trick to
easily remember which order things should appear in tags.

Some formats, such as MediaWiki, support the opposite syntax:

    [[Page Title|Link]]

## PAGE LINKS

To link to another Gollum wiki page, use the Gollum Page Link Tag.

    [[Frodo Baggins]]

The above tag will create a link to the corresponding page file named
`Frodo-Baggins.ext` where `ext` may be any of the allowed extension types. The
conversion is as follows:

1. Replace any spaces (U+0020) with dashes (U+002D)
2. Replace any slashes (U+002F) with dashes (U+002D)

If you'd like the link text to be something that doesn't map directly to the
page name, you can specify the actual page name after a pipe:

    [[Frodo|Frodo Baggins]]

The above tag will link to `Frodo-Baggins.ext` using "Frodo" as the link text.

The page file may exist anywhere in the directory structure of the repository.
Gollum does a breadth first search and uses the first match that it finds.

Here are a few more examples:

    [[J. R. R. Tolkien]] -> J.-R.-R.-Tolkien.ext
    [[Movies / The Hobbit]] -> Movies---The-Hobbit.ext
    [[モルドール]] -> モルドール.ext


## EXTERNAL LINKS

As a convenience, simple external links can be placed within brackets and they
will be linked to the given URL with the URL as the link text. For example:

    [[http://example.com]]

External links must begin with either "http://" or "https://". If you need
something more flexible, you can resort to the link syntax in the page's
underlying markup format.


## ABSOLUTE VS. RELATIVE VS. EXTERNAL PATH

For Gollum tags that operate on static files (images, PDFs, etc), the paths
may be referenced as either relative, absolute, or external. Relative paths
point to a static file relative to the page file within the directory
structure of the Gollum repo (even though after conversion, all page files
appear to be top level). These paths are NOT prefixed with a slash. For
example:

    gollum.pdf
    docs/diagram.png

Absolute paths point to a static file relative to the Gollum repo's
root, regardless of where the page file is stored within the directory
structure. These paths ARE prefixed with a slash. For example:

    /pdfs/gollum.pdf
    /docs/diagram.png

External paths are full URLs. An external path must begin with either
"http://" or "https://". For example:

    http://example.com/pdfs/gollum.pdf
    http://example.com/images/diagram.png

All of the examples in this README use relative paths, but you may use
whatever works best in your situation.


## FILE LINKS

To link to static files that are contained in the Gollum repository you should
use the Gollum File Link Tag.

    [[Gollum|gollum.pdf]]

The first part of the tag is the link text. The path to the file appears after
the pipe.


## IMAGES

To display images that are contained in the Gollum repository you should use
the Gollum Image Tag. This will display the actual image on the page.

    [[gollum.png]]

In addition to the simple format, there are a variety of options that you
can specify between pipe delimiters.

To specify alt text, use the `alt=` option. Default is no alt text.

    [[gollum.png|alt=Gollum and his precious wiki]]

To place the image in a frame, use the `frame` option. When combined with the
`alt=` option, the alt text will be used as a caption as well. Default is no
frame.

    [[gollum.png|frame|alt=Gollum and his precious wiki]]

To specify the alignment of the image on the page, use the `align=` option.
Possible values are `left`, `center`, and `right`. Default is `left`.

    [[gollum.png|align=center]]

To float an image so that text flows around it, use the `float` option. When
`float` is specified, only `left` and `right` are valid `align` options.
Default is not floating. When floating is activated but no alignment is
specified, default alignment is `left`.

    [[gollum.png|float]]

By default text will fill up all the space around the image. To control how
much should show up use this tag to stop and start a new block so that
additional content doesn't fill in.

    [[_]]

To specify a max-width, use the `width=` option. Units must be specified in
either `px` or `em`.

    [[gollum.png|width=400px]]

To specify a max-height, use the `height=` option. Units must be specified in
either `px` or `em`.

    [[gollum.png|height=300px]]

Any of these options may be composed together by simply separating them with
pipes.


## ESCAPING GOLLUM TAGS

If you need the literal text of a wiki or static link to show up in your final
wiki page, simply preface the link with a single quote (like in LISP):

    '[[Page Link]]
    '[[File Link|file.pdf]]
    '[[image.jpg]]

This is useful for writing about the link syntax in your wiki pages.

## TABLE OF CONTENTS

Gollum has a special tag to insert a table of contents:

    [[_TOC_]]

This tag is case sensitive, use all upper case.  The TOC tag can be inserted
into the `_Header`, `_Footer` or `_Sidebar` files too.

There is also a wiki option `:universal_toc` which will display a
table of contents at the top of all your wiki pages if it is enabled:

```ruby
Gollum::Wiki.new("my-gollum-repo.git", {:universal_toc => true})
```

## SYNTAX HIGHLIGHTING

In page files you can get automatic syntax highlighting for a wide range of
languages (courtesy of [Pygments](http://pygments.org/) - must install
separately) by using the following syntax:

    ```ruby
      def foo
        puts 'bar'
      end
    ```

The block must start with three backticks, at the beginning of a line or
indented with any number of spaces or tabs.
After that comes the name of the language that is contained by the
block. The language must be one of the `short name` lexer strings supported by
Pygments. See the [list of lexers](http://pygments.org/docs/lexers/) for valid
options.

The block contents should be indented at the same level than the opening backticks.
If the block contents are indented with an additional two spaces or one tab,
then that whitespace will be ignored (this makes the blocks easier to read in plaintext).

The block must end with three backticks indented at the same level than the opening
backticks.

### GITHUB SYNTAX HIGHLIGHTING

As an extra feature, you can syntax highlight a file from your repository, allowing
you keep some of your sample code in the main repository. The code-snippet is
updated when the wiki is rebuilt. You include github code like this:

    ```html:github:gollum/gollum-lib/master/test/file_view/1_file.txt```

This will make the builder look at the **gollum user**, in the **gollum-lib project**,
in the **master branch**, at path **test/file_view/1_file.txt**. It will be
rewritten to:

    ```html
    <ol class="tree">
      <li class="file"><a href="0">0</a></li>
    </ol>
    ```

Which will be parsed as HTML code during the Pygments run, and thereby coloured
appropriately.

## MATHEMATICAL EQUATIONS

Start gollum with the `--mathjax` flag. Read more about [MathJax](http://docs.mathjax.org/en/latest/index.html) on the web. Gollum uses the `TeX-AMS-MML_HTMLorMML` config with the `autoload-all` extension.

Inline math:

- $2^2$
- `\\(2^2\\)`

Display math:

- $$2^2$$
- [2^2]

## SEQUENCE DIAGRAMS

You may imbed sequence diagrams into your wiki page (rendered by
[WebSequenceDiagrams](http://www.websequencediagrams.com) by using the
following syntax:

    {{{{{{ blue-modern
      alice->bob: Test
      bob->alice: Test response
    }}}}}}

You can replace the string "blue-modern" with any supported style.

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
page = wiki.page('page-name')
# => <Gollum::Page>

page.raw_data
# => "# My wiki page"

page.formatted_data
# => "<h1>My wiki page</h1>"

page.format
# => :markdown

vsn = page.version
# => <Grit::Commit>

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
# => [<Grit::Commit, <Grit::Commit, <Grit::Commit>]

vsns.first.id
# => '3ca43e12377ea1e32ea5c9ce5992ec8bf266e3e5'

vsns.first.authored_date
# => Sun Mar 28 19:11:21 -0700 2010
```

Get a specific version of a given canonical page file:

```ruby
wiki.page('page-name', '5ec521178e0eec4dc39741a8978a2ba6616d0f0a')
```

Get the latest version of a given static file:

```ruby
file = wiki.file('asset.js')
# => <Gollum::File>

file.raw_data
# => "alert('hello');"

file.version
# => <Grit::Commit>
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
exist) and commit the change. The file will be written at the repo root.

```ruby
wiki.write_page('Page Name', :markdown, 'Page contents', commit)
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
gollum-lib$ gem install --no-ri --no-rdoc pkg/gollum-lib*.gem
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
