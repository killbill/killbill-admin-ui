# mustache-js-rails

[![Gem Version](https://badge.fury.io/rb/mustache-js-rails.svg)][gem_version]

[gem_version]: https://rubygems.org/gems/mustache-js-rails

mustache-js-rails integrates [mustache.js](https://github.com/janl/mustache.js)
and [mustache jQuery integration](https://github.com/jonnyreeves/jquery-Mustache) with rails 3.1+ asset pipeline.

Integrated versions are:

  * mustache.js - <b id="mustache-js-version">4.1.0</b>
  * jQuery mustache - <b id="jquery-mustache-js-version">0.2.8</b>

### Installation

Add

``` ruby
gem 'mustache-js-rails'`
```

to your `Gemfile`

and

```javascript
//= require mustache
```

to your `app/assets/javascripts/application.js` or other js manifest file.

For jQuery integration also add:

```javascript
//= require jquery.mustache
```
