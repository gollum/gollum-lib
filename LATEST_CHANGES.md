# 6.1.0

This is largely a bugfix release.

New features:

- Added support for GitLab style PlantUML blocks and additional diagram types. #461 (@dometto)

Bugfixes:

- Ensured "copy to clipboard" button appears normally when Pygments is enabled. #460 (@x789034)
- Don't use real `anon.com` domain in anonymous git committer emails. #458 (@jmtd)
- Removed dead code, `Gollum::FileView`. #455 (@benjaminwil)
- HTML escape YAML after parsing to prevent invalidating YAML string #454 (@dometto)
- Ensured `[[include:<path>]]` helper works with absolute paths. Note that this was meant to be included in the 6.0 release but was not. Sorry for any confusion. #452 (@dometto)
