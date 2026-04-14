# frozen_string_literal: true

require_relative "multi_json/concurrency"
require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"

# A unified interface for JSON libraries in Ruby
#
# MultiJson allows swapping between JSON backends without changing your code.
# It auto-detects available JSON libraries and uses the fastest one available.
#
# ## Method-definition patterns
#
# The current public API uses two patterns, each chosen for a specific reason:
#
# 1. ``module_function`` creates both a class method and a private instance
#    method from a single ``def``. This is used for the hot-path API
#    (``adapter``, ``use``, ``adapter=``, ``load``, ``dump``,
#    ``current_adapter``) so that both ``MultiJson.load(...)`` and legacy
#    ``Class.new { include MultiJson }.new.send(:load, ...)`` invocations
#    work through the same body. The instance versions are re-publicized
#    below so YARD renders them as part of the public API.
# 2. ``def self.foo`` creates only a singleton method, giving mutation
#    testing a single canonical definition to target. This is used for
#    {.with_adapter}, which needs precise mutation coverage of its
#    fiber-local save/restore logic.
#
# Deprecated public API (``decode``, ``encode``, ``engine``, etc.) lives in
# {file:lib/multi_json/deprecated.rb} so this file stays focused on the
# current surface.
#
# @example Basic usage
#   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
#   MultiJson.dump({foo: "bar"})     #=> '{"foo":"bar"}'
#
# @example Specifying an adapter
#   MultiJson.use(:oj)
#   MultiJson.load('{"foo":"bar"}', adapter: :json_gem)
#
# @api public
module MultiJson
  extend Options
  extend AdapterSelector

  # Tracks which deprecation warnings have already been emitted so each one
  # fires at most once per process. Stored as a Set rather than a Hash so
  # presence checks have unambiguous semantics for mutation tests.
  DEPRECATION_WARNINGS_SHOWN = Set.new
  private_constant :DEPRECATION_WARNINGS_SHOWN

  class << self
    private

    # Emit a deprecation warning at most once per process for the given key
    #
    # Defined as a singleton method (rather than via module_function) so
    # there is exactly one definition for mutation tests to target. The
    # deprecated method bodies invoke this via ``warn_deprecation_once(...)``
    # (singleton callers) and via the private instance delegates routing
    # through the singleton for legacy ``include MultiJson`` consumers.
    #
    # @api private
    # @param key [Symbol] identifier for the deprecation (typically the method name)
    # @param message [String] warning message to emit on first call
    # @return [void]
    # @example
    #   MultiJson.send(:warn_deprecation_once, :foo, "MultiJson.foo is deprecated")
    def warn_deprecation_once(key, message)
      Concurrency.synchronize(:deprecation_warnings) do
        return if DEPRECATION_WARNINGS_SHOWN.include?(key)

        Kernel.warn(message)
        DEPRECATION_WARNINGS_SHOWN.add(key)
      end
    end
  end

  # Resolve the ``ParseError`` constant for an adapter class
  #
  # The result is memoized on the adapter class itself in a
  # ``@_multi_json_parse_error`` ivar so subsequent ``MultiJson.load``
  # calls skip the constant lookup entirely. The lookup is performed
  # with ``inherit: false`` so a stray top-level ``::ParseError``
  # constant in the host process is correctly ignored on every
  # supported Ruby implementation — TruffleRuby's ``::`` operator
  # walks the ancestor chain and would otherwise pick up the top-level
  # constant. Custom adapters that don't define their own
  # ``ParseError`` get a clear {AdapterError} instead of the bare
  # ``NameError`` Ruby would raise from the rescue clause.
  #
  # @api private
  # @param adapter_class [Class] adapter class to inspect
  # @return [Class] the adapter's ParseError class
  # @raise [AdapterError] when the adapter doesn't define ParseError
  def self.parse_error_class_for(adapter_class)
    cached = adapter_class.instance_variable_get(:@_multi_json_parse_error)
    return cached if cached

    resolved = adapter_class.const_get(:ParseError, false)
    adapter_class.instance_variable_set(:@_multi_json_parse_error, resolved)
  rescue NameError
    raise AdapterError, "Adapter #{adapter_class} must define a ParseError constant"
  end

  # ===========================================================================
  # Public API (module_function: class + private instance method)
  # ===========================================================================

  # @!visibility private
  module_function

  # Returns the current adapter class
  #
  # Honors a fiber-local override set by {.with_adapter} so concurrent
  # blocks observe their own adapter without clobbering the process-wide
  # default. Falls back to the process default when no override is set.
  #
  # @api public
  # @return [Class] the current adapter class
  # @example
  #   MultiJson.adapter  #=> MultiJson::Adapters::Oj
  def adapter
    override = Fiber[:multi_json_adapter]
    return override if override

    @adapter ||= use(nil)
  end

  # Sets the adapter to use for JSON operations
  #
  # The merged-options cache is only reset when the new adapter loads
  # successfully. A failed ``use(:nonexistent)`` leaves the cache in
  # place so the previously-active adapter keeps its cached entries.
  #
  # @api public
  # @param new_adapter [Symbol, String, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.use(:oj)
  def use(new_adapter)
    loaded = load_adapter(new_adapter)
    Concurrency.synchronize(:adapter) do
      OptionsCache.reset
      @adapter = loaded
    end
  end

  # Sets the adapter to use for JSON operations
  #
  # @api public
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.adapter = :json_gem
  alias_method :adapter=, :use
  module_function :adapter=

  # Parses a JSON string into a Ruby object
  #
  # Returns ``nil`` for ``nil``, empty, and whitespace-only inputs
  # instead of raising. Pass an explicit non-blank string if you want
  # to surface a {ParseError} for empty payloads at the call site.
  #
  # @api public
  # @param string [String, #read] JSON string or IO-like object
  # @param options [Hash] parsing options (adapter-specific)
  # @return [Object, nil] parsed Ruby object, or nil for blank input
  # @raise [ParseError] if parsing fails
  # @raise [AdapterError] if the adapter doesn't define a ``ParseError`` constant
  # @example
  #   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
  #   MultiJson.load("")               #=> nil
  #   MultiJson.load("   \n")          #=> nil
  def load(string, options = {})
    adapter_class = current_adapter(options)
    parse_error_class = MultiJson.parse_error_class_for(adapter_class)
    begin
      adapter_class.load(string, options)
    rescue parse_error_class => e
      raise ParseError.build(e, string)
    end
  end

  # Returns the adapter to use for the given options
  #
  # ``nil`` is accepted as a no-options sentinel — explicit
  # ``current_adapter(nil)`` calls fall through to the process default
  # adapter without raising.
  #
  # @api public
  # @param options [Hash, nil] options that may contain :adapter key, or
  #   nil to use the process default
  # @return [Class] adapter class
  # @example
  #   MultiJson.current_adapter(adapter: :oj)  #=> MultiJson::Adapters::Oj
  def current_adapter(options = {})
    options ||= Options::EMPTY_OPTIONS
    adapter_override = options[:adapter]
    adapter_override ? load_adapter(adapter_override) : adapter
  end

  # Serializes a Ruby object to a JSON string
  #
  # @api public
  # @param object [Object] object to serialize
  # @param options [Hash] serialization options (adapter-specific)
  # @return [String] JSON string
  # @example
  #   MultiJson.dump({foo: "bar"})  #=> '{"foo":"bar"}'
  def dump(object, options = {})
    current_adapter(options).dump(object, options)
  end

  # Re-publicize the instance versions of the module_function methods so
  # YARD/yardstick render them as part of the public API and legacy
  # ``include MultiJson`` consumers can call them without ``.send``.
  public :adapter, :use, :adapter=, :load, :current_adapter, :dump

  # ===========================================================================
  # Public API (def self.foo: singleton-only, for mutation-test precision)
  # ===========================================================================

  # Executes a block using the specified adapter
  #
  # Defined as a singleton method so mutation testing has exactly one
  # definition to target. The override is stored in fiber-local storage
  # so concurrent fibers and threads each see their own adapter without
  # racing on a shared module variable; nested calls save and restore
  # the previous fiber-local value.
  #
  # @api public
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   MultiJson.with_adapter(:json_gem) { MultiJson.dump({}) }
  def self.with_adapter(new_adapter)
    previous_override = Fiber[:multi_json_adapter]
    Fiber[:multi_json_adapter] = load_adapter(new_adapter)
    yield
  ensure
    Fiber[:multi_json_adapter] = previous_override
  end

  # ===========================================================================
  # Private instance-method delegates for the singleton-only methods above
  # ===========================================================================

  private

  # Instance-method delegate for {MultiJson.with_adapter}
  #
  # @api private
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:with_adapter, :json_gem) { ... }
  def with_adapter(new_adapter, &)
    MultiJson.with_adapter(new_adapter, &)
  end
end

require_relative "multi_json/deprecated"
