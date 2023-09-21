# frozen_string_literal: true

require 'test_helper'

module Kaui
  class TagDefinitionTest < ActiveSupport::TestCase
    include Kaui::KillbillTestHelper

    test 'can detect system tags' do
      1.upto(9).each do |i|
        assert Kaui::TagDefinition.new(id: "00000000-0000-0000-0000-00000000000#{i}").system_tag?
      end
      assert !Kaui::TagDefinition.new(id: SecureRandom.uuid).system_tag?
    end

    test 'can list all user and control tags' do
      tenant = create_tenant
      assert_not_nil(tenant)
      options_for_klient = build_options(tenant)
      tags = Kaui::TagDefinition.all_for_account(options_for_klient)
      assert_equal 9, tags.count
    end
  end
end
