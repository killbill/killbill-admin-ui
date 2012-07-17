module Kaui
  class Product
    attr_reader :id
    attr_reader :product_name
    attr_reader :product_category
    attr_reader :billing_period

    def initialize(data = {})
      @id = data[:id]
      @product_name = data[:product_name]
      @product_category = data[:product_category]
      @billing_period = data[:billing_period]
    end
  end

  SAMPLE_BASE_PRODUCTS = [
    Kaui::Product.new(:id => "product1", :product_category => "Base", :product_name => "OneBase", :billing_period => "ANNUAL"),
    Kaui::Product.new(:id => "product2", :product_category => "Base", :product_name => "TwoBase", :billing_period => "MONTHLY"),
  ]
  SAMPLE_ADDON_PRODUCTS = [
    Kaui::Product.new(:id => "addon1", :product_category => "AddOn", :product_name => "OneAddon", :billing_period => "MONTHLY"),
    Kaui::Product.new(:id => "addon2", :product_category => "AddOn", :product_name => "TwoAddon", :billing_period => "MONTHLY"),
  ]
end