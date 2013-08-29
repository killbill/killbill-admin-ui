class Kaui::Base
  include Kaui::RailsMethods

  attr_reader :errors

  @@attribute_names = {}

  def self.define_attr(*args)
    send("attr_accessor".to_sym, *args)
    args.each do |attr_name|
      @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
      @@attribute_names[self.name][attr_name.to_sym] = { :cardinality => :one }
    end
  end
  define_attr :audit_logs

  def self.has_one(attr_name, type = nil)
    send("attr_accessor".to_sym, attr_name)
    @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
    @@attribute_names[self.name][attr_name.to_sym] = { :type => type, :cardinality => :one }
  end

  def self.has_many(attr_name, type = nil)
    send("attr_accessor".to_sym, attr_name)
    @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
    @@attribute_names[self.name][attr_name.to_sym] = { :type => type, :cardinality => :many }
  end

  def self.from_json(json_text)
    json_hash = ActiveSupport::JSON.decode(json_text)
    return self.new(json_hash)
  end

  def initialize(attributes = {})
    # We can come here either from the Killbill API (attributes will be a JSON hash,
    # with camel cased keys) or from e.g. Rails forms (attributes will be a hash with
    # snake cased keys).
    # Either way, convert the keys to snake case as our attributes are snake cased.
    self.attributes = Kaui::Base.convert_hash_keys(attributes)

    # Make has_many associations return [] instead of nil by default
    @@attribute_names[self.class.name].each do |name, type_desc|
      val = send("#{name}")
      send("#{name}=", []) if val.nil? and !type_desc.nil? and type_desc[:cardinality] == :many
    end

    # Mark the record as persisted if we have an id
    @persisted = to_param.present?

    # Errors for form validations
    @errors = ActiveModel::Errors.new(self)
  end

  def attributes=(values)
    values.each do |name, value|
      type_desc = @@attribute_names[self.class.name][name.to_sym]
      unless type_desc.nil?
        type = type_desc[:type]
        if type_desc[:cardinality] == :many && !type.nil? && value.is_a?(Array)
          newValue = []
          value.each do |val|
            if val.is_a?(Hash)
              newValue << type.to_s.constantize.new(val)
            else
              newValue << val
            end
          end
          value = newValue
        elsif type_desc[:cardinality] == :one && !type.nil? && value.is_a?(Hash)
          value = type.to_s.constantize.new(value)
        end
      end
      send("#{name}=", value)
    end
  end

  def to_hash
    result = {}
    @@attribute_names[self.class.name].each do |name, type_desc|
      val = send("#{name}")
      unless val.nil? || type_desc.nil?
        type = type_desc[:type]
        if type_desc[:cardinality] == :many && !type.nil? && val.is_a?(Array)
          newVal = []
          val.each do |curVal|
            newVal << curVal.as_json(:root => false)
          end
          val = newVal
        elsif type_desc[:cardinality] == :one && !type.nil?
          val = val.as_json(:root => false)
        end
        result[name.to_s] = val
      end
    end
    result
  end

  def self.to_money(amount, currency)
    begin
      return Money.new(amount.to_f * 100, currency)
    rescue => e
    end if currency.present?
    Money.new(amount.to_f * 100, "USD")
  end

  def self.camelize(value)
    case value
      when Array
        value.map {|v| camelize(v) }
      when Hash
        value.inject({}) {|result, (k, v)| result.merge!(k.to_s.camelize(:lower).to_sym => camelize(v)) }
      else
        value
    end
  end

  # Convert a hash with camel cased keys into a hash with snake cased keys:
  #
  #   { :accountId => 12 } becomes { :account_id => 12 }
  #
  def self.convert_hash_keys(value)
    case value
      when Hash
        Hash[value.map { |k, v| [k.to_s.underscore.to_sym, convert_hash_keys(v)] }]
      else
        value
     end
  end


end
