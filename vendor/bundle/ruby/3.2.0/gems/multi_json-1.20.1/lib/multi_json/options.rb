# frozen_string_literal: true

module MultiJson
  # Mixin providing configurable load/dump options
  #
  # Supports static hashes or dynamic callables (procs/lambdas).
  # Extended by both MultiJson (global options) and Adapter classes.
  #
  # @api private
  module Options
    # Steep needs an inline `#:` annotation here because `{}.freeze`
    # would be inferred as `Hash[untyped, untyped]` and trip
    # `UnannotatedEmptyCollection`. The annotation requires
    # `Hash.new.freeze` (not the `{}.freeze` rubocop would prefer)
    # because the `#:` cast only applies to method-call results.
    EMPTY_OPTIONS = Hash.new.freeze #: options # rubocop:disable Style/EmptyLiteral

    # Set options for load operations
    #
    # @api public
    # @param options [Hash, Proc] options hash or callable
    # @return [Hash, Proc] the options
    # @example
    #   MultiJson.load_options = {symbolize_keys: true}
    def load_options=(options)
      OptionsCache.reset
      @load_options = options
    end

    # Set options for dump operations
    #
    # @api public
    # @param options [Hash, Proc] options hash or callable
    # @return [Hash, Proc] the options
    # @example
    #   MultiJson.dump_options = {pretty: true}
    def dump_options=(options)
      OptionsCache.reset
      @dump_options = options
    end

    # Get options for load operations
    #
    # When `@load_options` is a callable (proc/lambda), it's invoked
    # with `args` as positional arguments — typically the merged
    # options hash from `Adapter.merged_load_options`. When it's a
    # plain hash, `args` is ignored.
    #
    # @api public
    # @param args [Array<Object>] forwarded to the callable, ignored otherwise
    # @return [Hash] resolved options hash
    # @example
    #   MultiJson.load_options  #=> {}
    def load_options(*args)
      resolve_options(@load_options, *args) || default_load_options
    end

    # Get options for dump operations
    #
    # @api public
    # @param args [Array<Object>] forwarded to the callable, ignored otherwise
    # @return [Hash] resolved options hash
    # @example
    #   MultiJson.dump_options  #=> {}
    def dump_options(*args)
      resolve_options(@dump_options, *args) || default_dump_options
    end

    # Get default load options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_load_options
      Concurrency.synchronize(:default_options) { @default_load_options ||= EMPTY_OPTIONS }
    end

    # Get default dump options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_dump_options
      Concurrency.synchronize(:default_options) { @default_dump_options ||= EMPTY_OPTIONS }
    end

    private

    # Resolves options from a hash or callable
    #
    # @api private
    # @param options [Hash, Proc, nil] options configuration
    # @param args [Array<Object>] arguments forwarded to a callable provider
    # @return [Hash, nil] resolved options hash
    def resolve_options(options, *args)
      if options.respond_to?(:call)
        # @type var options: options_proc
        return invoke_callable(options, *args)
      end

      options.to_hash if options.respond_to?(:to_hash)
    end

    # Invokes a callable options provider
    #
    # @api private
    # @param callable [Proc] options provider
    # @param args [Array<Object>] arguments forwarded when the callable is non-arity-zero
    # @return [Hash] options returned by the callable
    def invoke_callable(callable, *args)
      callable.arity.zero? ? callable.call : callable.call(*args)
    end
  end
end
