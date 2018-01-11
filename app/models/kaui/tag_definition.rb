class Kaui::TagDefinition < KillBillClient::Model::TagDefinition

  # See org.killbill.billing.ObjectType in killbill-api
  ALL_OBJECT_TYPES = %w(ACCOUNT
     ACCOUNT_EMAIL
     BLOCKING_STATES
     BUNDLE
     CUSTOM_FIELD
     INVOICE
     PAYMENT
     TRANSACTION
     INVOICE_ITEM
     INVOICE_PAYMENT
     SUBSCRIPTION
     SUBSCRIPTION_EVENT
     PAYMENT_ATTEMPT
     PAYMENT_METHOD
     REFUND
     TAG
     TAG_DEFINITION
     TENANT
     TENANT_KVS)

  ALL_OBJECT_TYPES.each do |object_type|
    define_singleton_method "all_for_#{object_type.downcase}" do |options_for_klient|
      (self.all('NONE', options_for_klient).delete_if { |tag_definition| !tag_definition.applicable_object_types.include? object_type || tag_definition.is_control_tag }).sort
    end
  end

  def is_system_tag?
    return false unless id.present?
    last_group = id.split('-')[4]

    is_system_tag = true
    last_group.split(//).each_with_index do |c, i|
      unless (c == '0' and i < 11) or (c.to_i > 0 and i == 11)
        is_system_tag = false
        break
      end
    end
    is_system_tag
  end

  def <=>(tag_definition)
    # System tags last
    return 1 if is_system_tag? and !tag_definition.is_system_tag?
    return -1 if !is_system_tag? and tag_definition.is_system_tag?
    name <=> tag_definition.name
  end

  def pretty_applicable_object_types
    applicable_object_types == ALL_OBJECT_TYPES ? 'Any' : applicable_object_types.join(', ')
  end
end
