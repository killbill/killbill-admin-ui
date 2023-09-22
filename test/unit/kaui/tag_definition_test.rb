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

    test 'can create awesome_customer tag and should return it for object_types=[ACCOUNT] tags ' do
      random_id = SecureRandom.uuid
      options_for_klient = build_options_for_klient

      tag_definition = Kaui::TagDefinition.new({
                                                 id: random_id,
                                                 is_control_tag: false,
                                                 name: 'awesome_customer',
                                                 description: 'A user-defined tag',
                                                 applicable_object_types: ['ACCOUNT']
                                               })
      tag_definition.create('kaui search test', nil, nil, options_for_klient) # creates 'awesome_customer tag definition for object_types=[ACCOUNT]

      tags = Kaui::TagDefinition.all_for_account(options_for_klient) # gets all tag definition list for object_types=[ACCOUNT]

      tags.each do |tag|
        next unless tag.id == random_id

        assert 'awesome_customer', tag.name # checks 'awesome_customer tag is available in the list or not
      end
    end

    test 'can list all account users and control tags' do
      options_for_klient = build_options_for_klient
      account_tags = Kaui::TagDefinition.all_for_account(options_for_klient)
      assert_equal 9, account_tags.count
    end

    test 'account tags list should not have WRITTEN_OFF tag' do
      options_for_klient = build_options_for_klient
      account_tags = Kaui::TagDefinition.all_for_account(options_for_klient)
      account_tags.each do |account_tag|
        assert_not_equal 'WRITTEN_OFF', account_tag.name
      end
    end

    test 'invoice related tags list should have WRITTEN_OFF tag' do
      options_for_klient = build_options_for_klient
      invoice_tags = Kaui::TagDefinition.all_for_invoice(options_for_klient)
      assert_equal 1, invoice_tags.count
      assert_equal 'WRITTEN_OFF', invoice_tags[0].name
    end

    def build_options_for_klient
      tenant = create_tenant # create a tenant for authorization
      assert_not_nil(tenant)
      build_options(tenant) # get options object which contains tenant's secret, apikey, username and password
    end
  end
end
