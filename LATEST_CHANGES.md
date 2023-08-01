# 6.0

* Default to local PlantUML server for security. #412. (@manofstick)
* Allow use of default branch name `main` or `master. Resolves https://github.com/gollum/gollum/issues/1813. (@dometto)
* Feature: [support for custom rendering of languages in codeblocks](https://github.com/gollum/gollum/wiki/Custom-language-handlers). #433. (@dometto)
* Support use of commit notes in Gollum::Committer. #435. (@dometto, @bartkamphorst)
* Remove octicons from gollum-lib. Icon macros must now be styled independently. #441. (@bartkamphorst)
* Huge performance increase for large wikis! :rocket: #437. (@dometto)

### Bugfixes

* Fix the use of boolean arguments in Macros. #441. (@dometto)
* Fix broken relative links: these were previously not rendered as relative. #443. (@dometto)