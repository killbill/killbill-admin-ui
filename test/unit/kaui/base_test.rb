require 'test_helper'

class Kaui::BaseTest < ActiveSupport::TestCase

  class Kaui::SomeKlass < Kaui::Base
    define_attr :attribute_id

    has_many :klasses, Kaui::SomeKlass
  end

  test "has_many association should return [] by default" do
    klass = Kaui::SomeKlass.new
    assert_equal [], klass.klasses
  end

  test "can serialize from hash" do
    klass = Kaui::SomeKlass.new(:attribute_id => 12)
    assert_equal 12, klass.attribute_id
  end

  test "can serialize from json" do
    klass = Kaui::SomeKlass.new(:attributeId => 12)
    assert_equal 12, klass.attribute_id
  end

  test "convert camelcase hash into snake case hash" do
    # Happy path
    new_hash = Kaui::Base.convert_hash_keys({:accountId=>12, :data_id=>14})
    assert_equal 12, new_hash[:account_id]
    assert_equal 14, new_hash[:data_id]
    assert_nil new_hash[:accountId]

    # Edge cases
    assert_nil Kaui::Base.convert_hash_keys(nil)
    assert_equal [], Kaui::Base.convert_hash_keys([])
    assert_equal Hash.new, Kaui::Base.convert_hash_keys({})
    assert_equal 1, Kaui::Base.convert_hash_keys(1)
  end
end