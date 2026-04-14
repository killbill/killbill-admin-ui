# MultiJSON

[![Tests](https://github.com/sferik/multi_json/actions/workflows/tests.yml/badge.svg)][tests]
[![Linter](https://github.com/sferik/multi_json/actions/workflows/linter.yml/badge.svg)][linter]
[![Mutant](https://github.com/sferik/multi_json/actions/workflows/mutant.yml/badge.svg)][mutant]
[![Typecheck](https://github.com/sferik/multi_json/actions/workflows/typecheck.yml/badge.svg)][typecheck]
[![Docs](https://github.com/sferik/multi_json/actions/workflows/docs.yml/badge.svg)][docs]
[![Maintainability](https://qlty.sh/badges/fde3f4a8-c331-44be-b1e6-45842137def9/maintainability.svg)][qlty]
[![Gem Version](https://badge.fury.io/rb/multi_json.svg)][gem]

Lots of Ruby libraries parse JSON and everyone has their favorite JSON coder.
Instead of choosing a single JSON coder and forcing users of your library to be
stuck with it, you can use MultiJSON instead, which will simply choose the
fastest available JSON coder. Here's how to use it:

```ruby
require "multi_json"

MultiJson.load('{"abc":"def"}')                       #=> {"abc" => "def"}
MultiJson.load('{"abc":"def"}', symbolize_keys: true) #=> {abc: "def"}
MultiJson.dump({abc: "def"})                          # convert Ruby back to JSON
MultiJson.dump({abc: "def"}, pretty: true)            # encoded in a pretty form (if supported by the coder)
```

`MultiJson.load` returns `nil` for `nil`, empty, and whitespace-only inputs
instead of raising, so a missing or blank payload is observable as a `nil`
return value rather than an exception. When loading invalid JSON, MultiJSON
will throw a `MultiJson::ParseError`. `MultiJson::DecodeError` and
`MultiJson::LoadError` are aliases for backwards compatibility.

```ruby
begin
  MultiJson.load("{invalid json}")
rescue MultiJson::ParseError => exception
  exception.data    #=> "{invalid json}"
  exception.cause   #=> JSON::ParserError: ...
  exception.line    #=> 1 (for adapters that report a location, e.g. Oj or the json gem)
  exception.column  #=> 2
end
```

`ParseError` instance has `cause` reader which contains the original exception.
It also has `data` reader with the input that caused the problem, and `line`/`column`
readers populated for adapters whose error messages include a location (Oj and the
json gem). Adapters that don't include one (Yajl, fast_jsonparser) leave both nil.

### Tuning the options cache

MultiJSON memoizes the merged option hash for each `load`/`dump` call so identical
option hashes don't trigger repeated work. The cache is bounded — defaulting to 1000
entries per direction — and applications that generate many distinct option hashes
can raise the ceiling at runtime:

```ruby
MultiJson::OptionsCache.max_cache_size = 5000
```

`max_cache_size` must be a positive integer; `0`, negative values, and
non-integers raise `ArgumentError`.

Lowering the limit only takes effect for *new* inserts; existing cache
entries are left in place until normal eviction trims them below the
new ceiling. Call `MultiJson::OptionsCache.reset` if you want to evict
immediately.

The `use` method, which sets the MultiJSON adapter, takes either a symbol or a
class (to allow for custom JSON parsers) that responds to both `.load` and `.dump`
at the class level.

When MultiJSON fails to load the specified adapter, it'll throw `MultiJson::AdapterError`
which inherits from `ArgumentError`.

### Writing a custom adapter

A custom adapter is any class that responds to two class methods plus
defines a `ParseError` constant:

```ruby
class MyAdapter
  ParseError = Class.new(StandardError)

  def self.load(string, options)
    # parse string into a Ruby object, raising ParseError on failure
  end

  def self.dump(object, options)
    # serialize object to a JSON string
  end
end

MultiJson.use(MyAdapter)
```

`ParseError` is required: `MultiJson.load` rescues `MyAdapter::ParseError`
to wrap parse failures in `MultiJson::ParseError`, and an adapter that
omits the constant raises `MultiJson::AdapterError` on the first parse
attempt instead of producing a confusing `NameError`.

For more, inherit from `MultiJson::Adapter` to pick up shared option
merging, the `defaults :load, ...` / `defaults :dump, ...` DSL, and the
blank-input short-circuit. The built-in adapters in
`lib/multi_json/adapters/` are working examples.

MultiJSON tries to have intelligent defaulting. If any supported library is
already loaded, MultiJSON uses it before attempting to load others. When no
backend is preloaded, MultiJSON walks its preference list and uses the first
one that loads successfully:

1. `fast_jsonparser`
2. `oj`
3. `yajl-ruby`
4. `jrjackson`
5. The JSON gem
6. `gson`

This order is a best-effort historical ranking by typical parse/dump
throughput on representative workloads, not a guaranteed benchmark. Real-world
performance depends on the document shape, the Ruby implementation, and
whether you're calling `load` or `dump`. The JSON gem is a Ruby default gem,
so it's always available as a last-resort fallback on any supported Ruby. If
you have a workload where a different backend is faster, set it explicitly
with `MultiJson.use(:your_adapter)`.

## Gem Variants

MultiJSON ships as two platform-specific gems. Bundler and RubyGems
automatically select the correct variant for your Ruby implementation:

|                                                | `ruby` platform (MRI) | `java` platform (JRuby) |
| ---------------------------------------------- | :---: | :---: |
| Runtime dependency                             | none  | [concurrent-ruby][concurrent-ruby] `~> 1.2` |
| [`fast_jsonparser`][fast_jsonparser] adapter   |   ✓   |       |
| [`oj`][oj] adapter                             |   ✓   |       |
| [`yajl`][yajl] adapter                         |   ✓   |       |
| [`json_gem`][json-gem] adapter                 |   ✓   |   ✓   |
| [`gson`][gson] adapter                         |       |   ✓   |
| [`jr_jackson`][jrjackson] adapter              |       |   ✓   |
| `OptionsCache` thread-safe store               | `Hash` + `Mutex` | `Concurrent::Map` |

## Supported Ruby Versions

This library aims to support and is [tested against](https://github.com/sferik/multi_json/actions/workflows/tests.yml) the following Ruby
implementations:

- Ruby 3.2
- Ruby 3.3
- Ruby 3.4
- Ruby 4.0
- [JRuby][jruby] 10.0 (targets Ruby 3.4 compatibility)
- [TruffleRuby][truffleruby] 33.0 (native and JVM)

If something doesn't work in one of these implementations, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

```ruby
spec.add_dependency 'multi_json', '~> 1.0'
```

## Copyright

Copyright (c) 2010-2026 Erik Berlin, Michael Bleigh, Josh Kalderimis, and Pavel
Pravosud. See [LICENSE][license] for details.

[concurrent-ruby]: https://github.com/ruby-concurrency/concurrent-ruby
[docs]: https://github.com/sferik/multi_json/actions/workflows/docs.yml
[fast_jsonparser]: https://github.com/anilmaurya/fast_jsonparser
[gem]: https://rubygems.org/gems/multi_json
[gson]: https://github.com/avsej/gson.rb
[jrjackson]: https://github.com/guyboertje/jrjackson
[jruby]: http://www.jruby.org/
[json-gem]: https://github.com/flori/json
[license]: LICENSE.md
[linter]: https://github.com/sferik/multi_json/actions/workflows/linter.yml
[macruby]: http://www.macruby.org/
[mutant]: https://github.com/sferik/multi_json/actions/workflows/mutant.yml
[oj]: https://github.com/ohler55/oj
[pvc]: http://docs.rubygems.org/read/chapter/16#page74
[qlty]: https://qlty.sh/gh/sferik/projects/multi_json
[semver]: http://semver.org/
[tests]: https://github.com/sferik/multi_json/actions/workflows/tests.yml
[truffleruby]: https://www.graalvm.org/ruby/
[typecheck]: https://github.com/sferik/multi_json/actions/workflows/typecheck.yml
[yajl]: https://github.com/brianmario/yajl-ruby
