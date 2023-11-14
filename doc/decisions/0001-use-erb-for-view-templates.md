# 1. Use ERB (Embedded Ruby) for view templates

Date: 9 March 2020

Status: Accepted

## Context

The original team developing this application decided to use the [Slim](http://slim-lang.com) templating engine for the view templates.

## Decision

We should switch to using ERB templates instead. This can happen incrementally, either as we add new templates, or when existing templates need to be modified.

Pros
----
* [ERB](https://ruby-doc.org/stdlib-2.7.0/libdoc/erb/rdoc/ERB.html) is part of the Ruby standard library, and is [the default used by Rails](https://guides.rubyonrails.org/action_view_overview.html) and so is likely to be more familiar to Ruby on Rails developers.
* Because ERB consists of plain HTML files with small amounts of Ruby code added (using `<% %>` tags), it is likely to be more familiar to content designers and interaction designers, particularly those who also use Nunjucks in the [GOV.UK Prototype Kit](https://govuk-prototype-kit.herokuapp.com/docs).
* Slim’s templating language can be confusing, particularly when managing whitespace (we have inadvertently rendered spaces between tags in the past), and when adding class names which contain a `!` character (which requires using the more generic `[]` attribute syntax instead of dot notation).
* It is generally fractionally faster to parse than other templating languages, although this may be negligible.

Cons
----
* Switching incrementally means that we’ll have a mixture of template formats within the project for some time, which may cause confusion.

## Alternatives

Sticking with Slim was discounted for the reasons above.

We could also have switched to another framework such as Haml or Mustache, but felt that there were strong benefits from following the Rails default.

## Consequences

When developing new features or refactoring existing code, we should convert existing Slim templates to ERB whenever practicable.
