# frozen_string_literal: true

# Deprecated public API kept around for one major release
#
# Each method here emits a one-time deprecation warning on first call and
# delegates to its current-API counterpart. The whole file is loaded by
# {MultiJson} so the deprecation surface stays out of the main module
# definition.
#
# @api private
module MultiJson
  class << self
    private

    # Define a deprecated alias that delegates to a new method name
    #
    # The generated singleton method emits a one-time deprecation
    # warning naming the replacement, then forwards all positional and
    # keyword arguments plus any block to ``replacement``. Used for the
    # ``decode`` / ``encode`` / ``engine*`` / ``with_engine`` /
    # ``default_engine`` aliases that are scheduled for removal in v2.0.
    #
    # @api private
    # @param name [Symbol] deprecated method name
    # @param replacement [Symbol] current-API method to delegate to
    # @return [Symbol] the defined method name
    # @example
    #   deprecate_alias :decode, :load
    def deprecate_alias(name, replacement)
      message = "MultiJson.#{name} is deprecated and will be removed in v2.0. Use MultiJson.#{replacement} instead."
      define_singleton_method(name) do |*args, **kwargs, &block|
        warn_deprecation_once(name, message)
        public_send(replacement, *args, **kwargs, &block)
      end
    end

    # Define a deprecated method whose body needs custom delegation
    #
    # Used for the ``default_options`` / ``default_options=`` pair
    # whose body fans out to multiple replacement methods, and for the
    # ``cached_options`` / ``reset_cached_options!`` no-op stubs that
    # have no current-API counterpart at all. The block runs in its
    # own lexical ``self``, which is the ``MultiJson`` module since
    # every call site sits inside ``module MultiJson`` below.
    #
    # @api private
    # @param name [Symbol] deprecated method name
    # @param message [String] warning to emit on first call
    # @yield body to evaluate after the warning
    # @return [Symbol] the defined method name
    # @example
    #   deprecate_method(:cached_options, "...") { nil }
    def deprecate_method(name, message, &body)
      define_singleton_method(name) do |*args, **kwargs|
        warn_deprecation_once(name, message)
        body.call(*args, **kwargs)
      end
    end
  end

  deprecate_alias :decode, :load
  deprecate_alias :encode, :dump
  deprecate_alias :engine, :adapter
  deprecate_alias :engine=, :adapter=
  deprecate_alias :default_engine, :default_adapter
  deprecate_alias :with_engine, :with_adapter

  deprecate_method(
    :default_options=,
    "MultiJson.default_options setter is deprecated\n" \
    "Use MultiJson.load_options and MultiJson.dump_options instead"
  ) { |value| self.load_options = self.dump_options = value }

  deprecate_method(
    :default_options,
    "MultiJson.default_options is deprecated\n" \
    "Use MultiJson.load_options or MultiJson.dump_options instead"
  ) { load_options }

  %i[cached_options reset_cached_options!].each do |name|
    deprecate_method(name, "MultiJson.#{name} method is deprecated and no longer used.") { nil }
  end

  private

  # Instance-method delegate for the deprecated default_options setter
  #
  # @api private
  # @deprecated Use {MultiJson.load_options=} and {MultiJson.dump_options=} instead
  # @param value [Hash] options hash
  # @return [Hash] the options hash
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:default_options=, symbolize_keys: true)
  def default_options=(value)
    MultiJson.default_options = value
  end

  # Instance-method delegate for the deprecated default_options getter
  #
  # @api private
  # @deprecated Use {MultiJson.load_options} or {MultiJson.dump_options} instead
  # @return [Hash] the current load options
  # @example
  #   class Foo; include MultiJson; end
  #   Foo.new.send(:default_options)
  def default_options
    MultiJson.default_options
  end
end
