class Kaui::Base
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  @@attribute_names = {}

  def self.define_attr(*args)
    send("attr_accessor".to_sym, *args)
    args.each do |attr_name|
      @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
      @@attribute_names[self.name][attr_name.to_sym] = { :cardinality => :one }
    end
  end

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
    self.attributes = attributes
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

  def ==(other)
    !other.nil? && self.class == other.class && self.to_hash == other.to_hash
  end

  def persisted?
    false
  end
end
