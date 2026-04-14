# Changelog

## 1.20.1
* Fix `JsonGem#load` raising `ParseError` on ASCII-8BIT strings that contain valid UTF-8 bytes ([#64](https://github.com/sferik/multi_json/issues/64)). Ruby HTTP clients tag response bodies as ASCII-8BIT by default; the 1.20.0 change from `force_encoding` to `encode` broke the dominant real-world case by trying to transcode each byte individually. Switch back to `force_encoding` followed by a `valid_encoding?` guard so genuinely invalid byte sequences still surface as `ParseError`.
* Validate custom adapters during `MultiJson.use` and `MultiJson.load`/`dump` with an `:adapter` option, raising `MultiJson::AdapterError` immediately if the adapter does not respond to `.load`, `.dump`, or define a `ParseError` constant.
* Validate `OptionsCache.max_cache_size=` to reject `nil`, zero, negative, and non-integer values with a clear `ArgumentError`.

## 1.20.0
* Drop the `UnannotatedEmptyCollection` Steep diagnostic override by inline-annotating `Options::EMPTY_OPTIONS` with `#: options` and routing `MultiJson.current_adapter`'s `||=` fallback through that constant. Also enable rubocop's `Layout/LeadingCommentSpace` `AllowSteepAnnotation` / `AllowRBSInlineAnnotation` so future inline `#:` casts don't need a per-line disable.
* Hoist the `block_given?` check in `MutexStore#fetch` outside `@mutex.synchronize` so the no-block read path runs the check once per call instead of inside the critical section.
* Short-circuit `Adapter.blank?` on inputs that start with `{` or `[` so the dominant JSON object and array load paths skip the blank-pattern regex entirely.
* Drop the `(...)` argument forwarding in `MultiJson::Options#load_options`, `dump_options`, `resolve_options`, and `invoke_callable` in favor of explicit `*args` so the signatures document that they forward positional arguments to a callable provider and nothing else.
* Collapse the five `MultiJson::Concurrency.synchronize_*` wrapper methods into a single `Concurrency.synchronize(name, &block)` keyed by symbol, with the mutex catalog in a `MUTEXES` hash. The synchronization surface is now one method instead of five and adding a new mutex is a one-line entry.
* Walk the superclass chain manually in `Adapter.walk_default_options` instead of allocating an `ancestors` array on every call. The dump/load hot path no longer pays for an iteration over the (mostly module) ancestor list when looking up an adapter's defaults.
* Add a `# frozen_string_literal: true` magic comment to every Ruby file in `lib/` and `test/`, and flip the `Style/FrozenStringLiteralComment` rubocop cop to `EnforcedStyle: always` so future files inherit the freeze.
* Include the original exception's class name in `MultiJson::AdapterError.build`'s formatted message so a downstream consumer reading just the wrapped error can distinguish a `LoadError` from a validator `ArgumentError` without having to inspect `error.cause` separately.
* Mark the five `MultiJson::Concurrency` mutex constants as `private_constant` and add matching `synchronize_*` wrapper methods so callers don't reach into the module's internals.
* DRY up `lib/multi_json/deprecated.rb` with a small `deprecate_alias` / `deprecate_method` DSL so adding or removing a deprecation is a one-liner instead of a 4-line copy of the warn-then-delegate template.
* Hoist a shared `Gson::Decoder` and `Gson::Encoder` to handle the empty-options case in the JRuby `Gson` adapter so the dominant `MultiJson.load(json)` / `MultiJson.dump(obj)` call path no longer allocates a fresh decoder/encoder per call.
* Memoize the per-adapter `ParseError` lookup in `MultiJson.parse_error_class_for` so the constant resolution runs at most once per adapter, instead of on every `MultiJson.load` call.
* Walk the superclass chain in `Adapter.default_load_options` / `default_dump_options` instead of copying the parent's defaults into the subclass at inheritance time, so a parent calling `defaults :load, ...` after a subclass has been defined now propagates to the subclass.
* Hold `@eviction_mutex` around `ConcurrentStore#reset`'s `@cache.clear` so a JRuby fetcher in the middle of its evict-then-insert sequence cannot interleave with a concurrent reset, mirroring `MutexStore#reset`'s mutex usage.
* Collect the five process-wide mutexes that protect MultiJson's lazy initializers and adapter swap into a new `MultiJson::Concurrency` module so the library's concurrency surface is documented in one place.
* Replace the per-adapter `loaded` lambdas in `AdapterSelector::ADAPTERS` with constant name strings, walked through `Object.const_defined?` directly. The lookup table is half as large and no longer holds six closure objects whose only job was to call `defined?`.
* Wrap `AdapterSelector#default_adapter_excluding` in `DEFAULT_ADAPTER_MUTEX` so concurrent callers can't both walk the detection chain and double-fire `fallback_adapter`'s one-time warning.
* Raise a clear `MultiJson::AdapterError` when a custom adapter passed to `MultiJson.load` does not define a `ParseError` constant, instead of letting the bare `NameError` from the rescue clause propagate.
* Drop the duplicate `Adapter::EMPTY_OPTIONS` constant in favor of the `MultiJson::Options::EMPTY_OPTIONS` it was shadowing.
* Defer the `fast_jsonparser` adapter's dump-delegate resolution until the first `dump` call instead of locking it in at file load time. The adapter no longer inherits from another adapter, so loading `multi_json/adapters/fast_jsonparser` before `oj` no longer locks the dump path to whichever adapter happened to be available at that moment.
* Make the lazy `default_load_options` and `default_dump_options` initializers in `MultiJson::Options` thread-safe so two threads accessing an adapter's defaults for the first time can't both run the `||=` initializer.
* Make `AdapterSelector#default_adapter`'s lazy `||=` initializer thread-safe so two threads racing past the unset `@default_adapter` ivar can't both run detection (and double-emit the fallback warning in the no-adapters-installed branch).
* Wrap `MultiJson.use`'s `OptionsCache.reset` and `@adapter` swap in a mutex so two threads calling `use` concurrently can't interleave their cache reset and adapter assignment.
* Stop relying on `Oj::ParseError`'s `::SyntaxError` ancestor when matching exceptions in `Oj::ParseError.===`. Walk the exception's ancestor chain by class name instead, so a future Oj release that re-parents its error class doesn't silently break our rescue clauses.
* Improve `AdapterSelector#load_adapter`'s error message for unrecognized adapter specs so it names the expected types and shows the offender's `inspect` output instead of just `to_s`.
* Validate the `value` argument in `Adapter.defaults` so a non-Hash (e.g. `defaults :load, "oops"`) raises `ArgumentError` at definition time instead of crashing later in the merge path.
* Skip `String#scrub` in `Adapter.blank?` when the input is already valid UTF-8 so the common load path no longer allocates a scrubbed copy on every call.
* Move `Oj#load`'s `:symbolize_keys` translation into a private `translate_load_options` helper that drops the redundant `:symbolize_keys` passthrough alongside `:symbol_keys`, mirroring the cleanup already in `JsonGem#load`.
* Skip the per-call hash merge in `JsonGem#dump` when `pretty: true` is the only option, passing `PRETTY_STATE_PROTOTYPE` directly.
* Type-check the `Yajl`, `JrJackson`, and `Gson` adapter wrappers under Steep, with stubbed RBS sigs for the underlying libraries living in `sig/external_libraries.rbs`.
* Unify `LOADED_ADAPTER_DETECTORS` and `REQUIREMENT_MAP` in `AdapterSelector` into a single `ADAPTERS` source-of-truth so the require path and detection lambda for each adapter live in one place.
* Extract deprecated public API (`decode`, `encode`, `engine`, `engine=`, `default_engine`, `with_engine`, `default_options`, `default_options=`, `cached_options`, `reset_cached_options!`) into `lib/multi_json/deprecated.rb` and drop the matching `Style/Documentation`, `Style/ModuleFunction`, and `Style/OpenStructUse` rubocop opt-outs.
* Validate the `action` argument in `Adapter.defaults` so a typo (e.g. `defaults :encode, ...`) raises `ArgumentError` at definition time instead of silently producing a no-op default.
* Drop the stale `ok_json` reference from the `fast_jsonparser` adapter's docstring.
* Remove the `MultiJson::REQUIREMENT_MAP` legacy alias; the canonical map already lives on `MultiJson::AdapterSelector`.
* Drop the dead `JrJackson` dump arity branch (and its SimpleCov filter). JrJackson 0.4.18+ accepts an options hash as the second argument to `Json.dump`.
* Drop the redundant `options.except(:adapter)` allocation in `JsonGem#dump`; `Adapter.merged_dump_options` already strips `:adapter` before the cached hash reaches the adapter.
* Forward all merged options through `Yajl#load` instead of honoring only `:symbolize_keys`.
* Tighten `Adapter.blank?` so it scrubs invalid UTF-8 bytes up front instead of swallowing every `ArgumentError` from the underlying `String` calls.
* Guard `ConcurrentStore` eviction against a TOCTOU race so two concurrent JRuby threads cannot both pass the size check and briefly exceed `OptionsCache.max_cache_size`.
* Synchronize `warn_deprecation_once` so concurrent fibers and threads cannot race past the membership check and emit the same one-time deprecation warning twice.
* Stop resetting `OptionsCache` when `MultiJson.use` raises so a failed `use(:nonexistent)` no longer discards the cached entries belonging to the still-active previous adapter.
* Stop mutating cached options in `JsonGem#load`, mirroring the cache-pollution fix already in place for `Oj#load`.
* Empty the mutant ignore list. The `Gson` and `JrJackson` ignores were dead — those adapters ship in the java-platform gem and aren't present when mutant runs on MRI — and `Store#reset`'s mutex wrapper is now directly tested by stubbing `Mutex#synchronize`.
* Remove the vendored `ok_json` adapter. The json gem has been a Ruby default gem since 1.9, so an external pure-Ruby fallback is no longer needed on any supported Ruby version. The last-resort fallback when no other JSON library can be loaded is now `json_gem`. The `ConvertibleHashKeys` helper module, which only `ok_json` used, is also removed.
* Surface parse error locations as `error.line` and `error.column` on `MultiJson::ParseError`, extracted from the underlying adapter's message for adapters that include one (Oj, the json gem).
* Make `MultiJson::OptionsCache.max_cache_size` configurable so applications that generate many distinct option hashes can raise the cache ceiling at runtime.
* Reorganize `lib/multi_json.rb` into clearer sections and document why both the `module_function` and singleton-only definition patterns coexist.
* Restructure `OptionsCache` backend selection so MRI and JRuby execute the same physical `require_relative` line, restoring JRuby's line coverage threshold to 100%.
* Drop the `ALIASES` constant in `AdapterSelector` in favor of an inline check; the only entry, `jrjackson` → `jr_jackson`, is now inlined into `load_adapter_by_name`.
* Document the `fast_jsonparser` adapter's parent class freeze at file load time.
* Stop mass-requiring adapter gems at the top of `adapter_selection_test.rb`, which polluted the global require cache and let later tests silently depend on adapters they had not explicitly loaded.
* Restore the mutex around `MutexStore#reset` for TruffleRuby, where the unguarded clear could race with concurrent fetches in a way the MRI GVL otherwise prevents.
* Fix `TestHelpers.yajl?` to check the actual `yajl-ruby` gem name.
* [Stop requiring the `oj` gem from the `fast_jsonparser` adapter](https://github.com/sferik/multi_json/issues/63): `fast_jsonparser` only implements parsing, so the adapter's `dump` side now inherits from whichever adapter MultiJson would otherwise pick (oj → yajl → jr_jackson → json_gem → gson → ok_json). Users who install `fast_jsonparser` no longer need to also install `oj`.
* [Split the gem into `ruby` and `java` platform variants](https://github.com/sferik/multi_json/commit/ca2c747570335f8d3b6b0904aae6ace41329aedd): the `java` variant adds `concurrent-ruby ~> 1.2` as a runtime dependency and ships the `gson` and `jr_jackson` adapters; the `ruby` variant has no runtime dependencies and ships the MRI-only adapters. Bundler selects the correct variant automatically.
* [Drop Oj 2.x compatibility branch](https://github.com/sferik/multi_json/commit/93897a45e2b2f3f6fa047ee00fc1e879ae137ec1): the Oj adapter now requires Oj `~> 3.0`.
* [Drop support for Ruby 3.0, Ruby 3.1, and JRuby 9.4](https://github.com/sferik/multi_json/commit/bc4547a5cee4d66294f2a1be04fe61f9d49235cd).
* [Add Ruby 4.0 to the CI matrix](https://github.com/sferik/multi_json/commit/bdf4999ea0c81f79c208e5fafb63f7474571b687).
* [Make `with_adapter` overrides fiber-local](https://github.com/sferik/multi_json/commit/7f7ce0e68f094bb9a26bf37a950c4794dc8e7292) so concurrent fibers and threads each observe their own adapter without racing on a shared module variable.
* [Raise `MultiJson::ParseError` on invalid UTF-8 in the `json_gem` adapter](https://github.com/sferik/multi_json/commit/2b5d14548fc67c5fdcaaee9b14d9f3eefe1f3493) instead of silently reinterpreting bytes with `force_encoding`.
* [Warn once for deprecated method aliases](https://github.com/sferik/multi_json/commit/5390bf311567388056724743121a665adab8ae8d): `decode`, `encode`, `engine`, `engine=`, `default_engine`, and `with_engine` now emit a one-time deprecation warning on first call and are scheduled for removal in a future major release.
* [Emit deprecation warnings only once per process](https://github.com/sferik/multi_json/commit/118f608c43aacb2ad36aa5f70b9084d48a9877c9) for `default_options`, `default_options=`, `cached_options`, and `reset_cached_options!` instead of on every call.
* [Document public API methods as `@api public`](https://github.com/sferik/multi_json/commit/5f3bd5397800cbf4b8f3a522e91364de1ad9079d) so `load`, `dump`, `use`, `with_adapter`, `current_adapter`, `adapter`, `load_options`, and `dump_options` appear in generated docs.
* [Add YARD documentation for the `Adapters` module and `ParseError` constants](https://github.com/sferik/multi_json/commit/3bc3beb76987a5711bf6c94ab176d5a84a42b063).
* [Stop mutating cached options in `Oj#load`](https://github.com/sferik/multi_json/commit/091d4f046dfb1d85816b04ef68c0850e5a97acdf): the adapter previously assigned `options[:symbol_keys]` on the shared cached hash, slowly polluting it with extra keys.
* [Stop mutating cached options in `OjCommon#prepare_dump_options`](https://github.com/sferik/multi_json/commit/089892e387b56036840b58b61593ce2b80fd72d6): `merge!(PRETTY_STATE_PROTOTYPE)` on the cached options hash removed `:pretty` and added prototype keys on every call, producing accidentally-correct results through cache reuse.
* [Call `to_h` on options to properly handle `JSON::State` objects](https://github.com/sferik/multi_json/commit/821ea32d5cafc223983b24b3260a1d4112aefab9).
* [Avoid allocating an options hash on the `dump`/`load` hot path](https://github.com/sferik/multi_json/commit/89a397718fff9e6cc5af8b7ef9fa19494894e6ce) by reusing a shared frozen empty hash for the no-options case.
* [Short-circuit empty input in `Adapter.blank?`](https://github.com/sferik/multi_json/commit/d3081a64eaf7755610a29c602dc6f0c5678643c6) before falling back to the regex match.
* [Replace the `LOADERS` strategy table with a `case` statement](https://github.com/sferik/multi_json/commit/562331a002dc87052797c53769610a719699c33c) in `AdapterSelector#load_adapter`.
* [Move `REQUIREMENT_MAP` from `MultiJson` into `AdapterSelector`](https://github.com/sferik/multi_json/commit/ab371e70d63b840386a3cf264611c2298c7c8250); `MultiJson::REQUIREMENT_MAP` remains as a deprecated alias.
* [Fix Bundler 4.0 permission error in CI](https://github.com/sferik/multi_json/commit/1fe4514e641e34dcf3ec9b62a2a76bfe0120c708).
* [Revert the Steep removal](https://github.com/sferik/multi_json/commit/883be03219d5178f83381333c3a354f59b4c8117) and restore the Steepfile, sig directory, and typecheck workflow.
* [Add workflow badges for linter, mutant, steep, and docs](https://github.com/sferik/multi_json/commit/88cf1bea1fb3056ad3a7c0f8ca828e194ee895dd).
* [Bump `actions/checkout` from 4 to 6](https://github.com/sferik/multi_json/commit/587f246d9ffd6991417af771fa0ce7059b337c40).
* [Update copyright year and alphabetize contributors by last name](https://github.com/sferik/multi_json/commit/233fb0ee1a375279d83c06ff6f702ec17d695b88).

## 1.19.1
* [Restore deprecated encode/decode methods](https://github.com/sferik/multi_json/commit/c5bf2fc95dfdde6b30d63fefb0b2f4aa29633969)

## 1.19.0
* [Fix serialization of ActiveSupport-enhanced objects](https://github.com/sferik/multi_json/commit/03a367813ebd7ed87eb22ea05249cc6453bb3c10)

## 1.18.0
* [Fix conflict between JSON gem and ActiveSupport](https://github.com/intridea/multi_json/issues/222)

## 1.17.0
* [Revert minimum ruby version requirement](https://github.com/sferik/multi_json/pull/16)

## 1.16.0
* [Remove NSJSONSerialization](https://github.com/sferik/multi_json/commit/0423d3b5886e93405f4c2221687b7e3329bd2940)
* [Stop referencing JSON::PRETTY\_STATE\_PROTOTYPE](https://github.com/sferik/multi_json/commit/58094d7a0583bf1f5052886806a032c00f16ffc5)
* [Drop support for Ruby versions < 3.2](https://github.com/sferik/multi_json/commit/ff3b42c4bc26cd6512914b7e5321976e948985dc)
* [Move repo from @intridea to @sferik](https://github.com/sferik/multi_json/commit/e87aeadbc9b9aa6df79818fa01bfc5fa959d8474)
* [JsonCommon: force encoding to UTF-8, not binary](https://github.com/sferik/multi_json/commit/34dd0247de07f2703c7d42a42d4cefc73635f3cc)
* [Stop setting defaults in JsonCommon](https://github.com/sferik/multi_json/commit/d5f9e6e72b99a7def695f430f72c8365998de625)
* [Make json\_pure an alias of json\_gem](https://github.com/sferik/multi_json/commit/9ff7c3dcbe3650e712b38e636ad19061a4c08d1a)

## 1.15.0
* [Improve detection of json_gem adapter](https://github.com/sferik/multi_json/commit/62d54019b17ebf83b28c8deb871a02a122e7d9cf)

## 1.14.1
* [Fix a warning in Ruby 2.7](https://github.com/sferik/multi_json/commit/26a94ab8c78a394cc237e2ea292c1de4f6ed30d7)

## 1.14.0
* [Support Oj 3.x gem](https://github.com/sferik/multi_json/commit/5d8febdbebc428882811b90d514f3628617a61d5)

## 1.13.1
* [Fix missing stdlib set dependency in oj adapter](https://github.com/sferik/multi_json/commit/c4ff66e7bee6fb4f45e54429813d7fada1c152b8)

## 1.13.0
* [Make Oj adapter handle JSON::ParseError correctly](https://github.com/sferik/multi_json/commit/275e3ffd8169797c510d23d9ef5b8b07e64c3b42)

## 1.12.2
* [Renew gem certificate](https://github.com/sferik/multi_json/commit/57922d898c6eb587cc9a28ba5724c11e81724700)

## 1.12.1
* [Prevent memory leak in OptionsCache](https://github.com/sferik/multi_json/commit/aa7498199ad272f3d4a13750d7c568a66047e2ee)

## 1.12.0
* [Introduce global options cache to improve peroformance](https://github.com/sferik/multi_json/commit/7aaef2a1bc2b83c95e4208b12dad5d1d87ff20a6)

## 1.11.2
* [Only pass one argument to JrJackson when two is not supported](https://github.com/sferik/multi_json/commit/e798fa517c817fc706982d3f3c61129b6651d601)

## 1.11.1
* [Dump method passes options throught for JrJackson adapter](https://github.com/sferik/multi_json/commit/3c730fd12135c3e7bf212f878958004908f13909)

## 1.11.0
* [Make all adapters read IO object before load](https://github.com/sferik/multi_json/commit/167f559e18d4efee05e1f160a2661d16dbb215d4)

## 1.10.1
* [Explicitly require stringio for Gson adapter](https://github.com/sferik/multi_json/commit/623ec8142d4a212fa0db763bb71295789a119929)
* [Do not read StringIO object before passing it to JrJackson](https://github.com/sferik/multi_json/commit/a6dc935df08e7b3d5d701fbb9298384c96df0fde)

## 1.10.0
* [Performance tweaks](https://github.com/sferik/multi_json/commit/58724acfed31866d079eaafb1cd824e341ade287)

## 1.9.3
* [Convert indent option to Fixnum before passing to Oj](https://github.com/sferik/multi_json/commit/826fc5535b863b74fc9f981dfdda3e26f1ee4e5b)

## 1.9.2
* [Enable use_to_json option for Oj adapter by default](https://github.com/sferik/multi_json/commit/76a4aaf697b10bbabd5d535d83cf1149efcfe5c7)

## 1.9.1
* [Remove unused LoadError file](https://github.com/sferik/multi_json/commit/65dedd84d59baeefc25c477fedf0bbe85e7ce2cd)

## 1.9.0
* [Rename LoadError to ParseError](https://github.com/sferik/multi_json/commit/4abb98fe3a90b2a7b3d1594515c8a06042b4a27d)
* [Adapter load failure throws AdapterError instead of ArgumentError](https://github.com/sferik/multi_json/commit/4da612b617bd932bb6fa1cc4c43210327f98f271)

## 1.8.4
* [Make Gson adapter explicitly read StringIO object](https://github.com/sferik/multi_json/commit/b58b498747ff6e94f41488c971b2a30a98760ef2)

## 1.8.3
* [Make JrJackson explicitly read StringIO objects](https://github.com/sferik/multi_json/commit/e1f162d5b668e5e4db5afa175361a601a8aa2b05)
* [Prevent calling #downcase on alias symbols](https://github.com/sferik/multi_json/commit/c1cf075453ce0110f7decc4f906444b1233bb67c)

## 1.8.2
* [Downcase adapter string name for OS compatibility](https://github.com/sferik/multi_json/commit/b8e15a032247a63f1410d21a18add05035f3fa66)

## 1.8.1
* [Let the adapter handle strings with invalid encoding](https://github.com/sferik/multi_json/commit/6af2bf87b89f44eabf2ae9ca96779febc65ea94b)

## 1.8.0
* [Raise MultiJson::LoadError on blank input](https://github.com/sferik/multi_json/commit/c44f9c928bb25fe672246ad394b3e5b991be32e6)

## 1.7.9
* [Explicitly require json gem code even when constant is defined](https://github.com/sferik/multi_json/commit/36f7906c66477eb4b55b7afeaa3684b6db69eff2)

## 1.7.8
* [Reorder JrJackson before json_gem](https://github.com/sferik/multi_json/commit/315b6e460b6e4dcdb6c82e04e4be8ee975d395da)
* [Update vendored OkJson to version 43](https://github.com/sferik/multi_json/commit/99a6b662f6ef4036e3ee94d7eb547fa72fb2ab50)

## 1.7.7
* [Fix options caching issues](https://github.com/sferik/multi_json/commit/a3f14c3661688c5927638fa6088c7b46a67e875e)

## 1.7.6
* [Bring back MultiJson::VERSION constant](https://github.com/sferik/multi_json/commit/31b990c2725e6673bf8ce57540fe66b57a751a72)

## 1.7.5
* [Fix warning '*' interpreted as argument prefix](https://github.com/sferik/multi_json/commit/b698962c7f64430222a1f06430669706a47aff89)
* [Remove stdlib warning](https://github.com/sferik/multi_json/commit/d06eec6b7996ac8b4ff0e2229efd835379b0c30f)

## 1.7.4
* [Cache options for better performance](https://github.com/sferik/multi_json/commit/8a26ee93140c4bed36194ed9fb887a1b6919257b)

## 1.7.3
* [Require json/ext to ensure extension version gets loaded for json_gem](https://github.com/sferik/multi_json/commit/942686f7e8597418c6f90ee69e1d45242fac07b1)
* [Rename JrJackson](https://github.com/sferik/multi_json/commit/078de7ba8b6035343c3e96b4767549e9ec43369a)
* [Prefer JrJackson to JSON gem if present](https://github.com/sferik/multi_json/commit/af8bd9799a66855f04b3aff1c488485950cec7bf)
* [Print a warning if outdated gem versions are used](https://github.com/sferik/multi_json/commit/e7438e7ba2be0236cfa24c2bb9ad40ee821286d1)
* [Loosen required_rubygems_version for compatibility with Ubuntu 10.04](https://github.com/sferik/multi_json/commit/59fad014e8fe41dbc6f09485ea0dc21fc42fd7a7)

## 1.7.2
* [Rename Jrjackson adapter to JrJackson](https://github.com/sferik/multi_json/commit/b36dc915fc0e6548cbad06b5db6f520e040c9c8b)
* [Implement jrjackson -> jr_jackson alias for back-compatability](https://github.com/sferik/multi_json/commit/aa50ab8b7bb646b8b75d5d65dfeadae8248a4f10)
* [Update vendored OkJson module](https://github.com/sferik/multi_json/commit/30a3f474e17dd86a697c3fab04f468d1a4fd69d7)

## 1.7.1
* [Fix capitalization of JrJackson class](https://github.com/sferik/multi_json/commit/5373a5e38c647f02427a0477cb8e0e0dafad1b8d)

## 1.7.0
* [Add load_options/dump_options to MultiJson](https://github.com/sferik/multi_json/commit/a153956be6b0df06ea1705ce3c1ff0b5b0e27ea5)
* [MultiJson does not modify arguments](https://github.com/sferik/multi_json/commit/58525b01c4c2f6635ba2ac13d6fd987b79f3962f)
* [Enable quirks_mode by default for json_gem/json_pure adapters](https://github.com/sferik/multi_json/commit/1fd4e6635c436515b7d7d5a0bee4548de8571520)
* [Add JrJackson adapter](https://github.com/sferik/multi_json/commit/4dd86fa96300aaaf6d762578b9b31ea82adb056d)
* [Raise ArgumentError on bad adapter input](https://github.com/sferik/multi_json/commit/911a3756bdff2cb5ac06497da3fa3e72199cb7ad)

## 1.6.1
* [Revert "Use JSON.generate instead of #to_json"](https://github.com/sferik/multi_json/issues/86)

## 1.6.0
* [Add gson.rb support](https://github.com/intridea/multi_json/pull/71)
* [Add MultiJson.default_options](https://github.com/intridea/multi_json/pull/70)
* [Add MultiJson.with_adapter](https://github.com/intridea/multi_json/pull/67)
* [Stringify all possible keys for ok_json](https://github.com/intridea/multi_json/pull/66)
* [Use JSON.generate instead of #to_json](https://github.com/sferik/multi_json/issues/73)
* [Alias MultiJson::DecodeError to MultiJson::LoadError](https://github.com/intridea/multi_json/pull/79)

## 1.5.1
* [Do not allow Oj or JSON to create symbols by searching for classes](https://github.com/sferik/multi_json/commit/193e28cf4dc61b6e7b7b7d80f06f74c76df65c41)

## 1.5.0
* [Add MultiJson.with\_adapter method](https://github.com/sferik/multi_json/commit/d14c5d28cae96557a0421298621b9499e1f28104)
* [Stringify all possible keys for ok\_json](https://github.com/sferik/multi_json/commit/73998074058e1e58c557ffa7b9541d486d6041fa)

## 1.4.0
* [Allow load/dump of JSON fragments](https://github.com/sferik/multi_json/commit/707aae7d48d39c85b38febbd2c210ba87f6e4a36)

## 1.3.7
* [Fix rescue clause for MagLev](https://github.com/sferik/multi_json/commit/39abdf50199828c50e85b2ce8f8ba31fcbbc9332)
* [Remove unnecessary check for string version of options key](https://github.com/sferik/multi_json/commit/660101b70e962b3c007d0b90d45944fa47d13ec4)
* [Explicitly set default adapter when adapter is set to nil or false](https://github.com/sferik/multi_json/commit/a9e587d5a63eafb4baee9fb211265e4dd96a26bc)
* [Fix Oj ParseError mapping for Oj 1.4.0](https://github.com/sferik/multi_json/commit/7d9045338cc9029401c16f3c409d54ce97f275e2)

## 1.3.6
* [Allow adapter-specific options to be passed through to Oj](https://github.com/sferik/multi_json/commit/d0e5feeebcba0bc69400dd203a295f5c30971223)

## 1.3.5
* [Add pretty support to Oj adapter](https://github.com/sferik/multi_json/commit/0c8f75f03020c53bcf4c6be258faf433d24b2c2b)

## 1.3.4
* [Use class \<\< self instead of module\_function to create aliases](https://github.com/sferik/multi_json/commit/ba1451c4c48baa297e049889be241a424cb05980)

## 1.3.3
* [Remove deprecation warnings](https://github.com/sferik/multi_json/commit/36b524e71544eb0186826a891bcc03b2820a008f)

## 1.3.2
* [Add ability to use adapter per call](https://github.com/sferik/multi_json/commit/106bbec469d5d0a832bfa31fffcb8c0f0cdc9bd3)
* [Add and deprecate default\_engine method](https://github.com/sferik/multi_json/commit/fc3df0c7a3e2ab9ce0c2c7e7617a4da97dd13f6e)

## 1.3.1
* [Only warn once for each instance a deprecated method is called](https://github.com/sferik/multi_json/commit/e21d6eb7da74b3f283995c1d27d5880e75f0ae84)

## 1.3.0
* [Implement load/dump; deprecate decode/encode](https://github.com/sferik/multi_json/commit/e90fd6cb1b0293eb0c73c2f4eb0f7a1764370216)
* [Rename engines to adapters](https://github.com/sferik/multi_json/commit/ae7fd144a7949a9c221dcaa446196ec23db908df)

## 1.2.0
* [Add support for Oj](https://github.com/sferik/multi_json/commit/acd06b233edabe6c44f226873db7b49dab560c60)

## 1.1.0
* [NSJSONSerialization support for MacRuby](https://github.com/sferik/multi_json/commit/f862e2fc966cac8867fe7da3997fc76e8a6cf5d4)

## 1.0.4
* [Set data context to DecodeError exception](https://github.com/sferik/multi_json/commit/19ddafd44029c6681f66fae2a0f6eabfd0f85176)
* [Allow ok\_json to fallback to to\_json](https://github.com/sferik/multi_json/commit/c157240b1193b283d06d1bd4d4b5b06bcf3761f8)
* [Add warning when using ok\_json](https://github.com/sferik/multi_json/commit/dd4b68810c84f826fb98f9713bfb29ab96888d57)
* [Options can be passed to an engine on encode](https://github.com/sferik/multi_json/commit/e0a7ff5d5ff621ffccc61617ed8aeec5816e81f7)

## 1.0.3
* [Array support for stringify\_keys](https://github.com/sferik/multi_json/commit/644d1c5c7c7f6a27663b11668527b346094e38b9)
* [Array support for symbolize\_keys](https://github.com/sferik/multi_json/commit/c885377d47a2aa39cb0d971fea78db2d2fa479a7)

## 1.0.2
* [Allow encoding of rootless JSON when ok\_json is used](https://github.com/sferik/multi_json/commit/d1cde7de97cb0f6152aef8daf14037521cdce8c6)

## 1.0.1
* [Correct an issue with ok\_json not being returned as the default engine](https://github.com/sferik/multi_json/commit/d33c141619c54cccd770199694da8fd1bd8f449d)

## 1.0.0
* [Remove ActiveSupport::JSON support](https://github.com/sferik/multi_json/commit/c2f4140141d785a24b3f56e58811b0e561b37f6a)
* [Fix @engine ivar warning](https://github.com/sferik/multi_json/commit/3b978a8995721a8dffedc3b75a7f49e5494ec553)
* [Only rescue from parsing errors during decoding, not any StandardError](https://github.com/sferik/multi_json/commit/391d00b5e85294d42d41347605d8d46b4a7f66cc)
* [Rename okjson engine and vendored lib to ok\_json](https://github.com/sferik/multi_json/commit/5bd1afc977a8208ddb0443e1d57cb79665c019f1)
* [Add StringIO support to json gem and ok\_json](https://github.com/sferik/multi_json/commit/1706b11568db7f50af451fce5f4d679aeb3bbe8f)

## 0.0.5
* [Trap all JSON decoding errors; raise MultiJson::DecodeError](https://github.com/sferik/multi_json/commit/dea9a1aef6dd1212aa1e5a37ab1669f9b045b732)

## 0.0.4
* [Fix default\_engine check for json gem](https://github.com/sferik/multi_json/commit/caced0c4e8c795922a109ebc00c3c4fa8635bed8)
* [Make requirement mapper an Array to preserve order in Ruby versions \< 1.9](https://github.com/sferik/multi_json/commit/526f5f29a42131574a088ad9bbb43d7f48439b2c)

## 0.0.3
* [Improve defaulting and documentation](https://github.com/sferik/twitter/commit/3a0e41b9e4b0909201045fa47704b78c9d949b73)

## 0.0.2
* [Rename to multi\_json](https://github.com/sferik/twitter/commit/461ab89ce071c8c9fabfc183581e0ec523788b62)

## 0.0.1
* [Initial commit](https://github.com/sferik/twitter/commit/518c21ab299c500527491e6c049ab2229e22a805)
