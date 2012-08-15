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
end