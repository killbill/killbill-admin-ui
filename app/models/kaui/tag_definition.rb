class Kaui::TagDefinition < Kaui::Base

  define_attr :id
  define_attr :name
  define_attr :description
  define_attr :is_control_tag
  define_attr :applicable_object_types

  def self.all(options_for_klient = {})
    Kaui::KillbillHelper.get_tag_definitions(options_for_klient)
  end

  def self.find(tag_definition_id, options_for_klient = {})
    Kaui::KillbillHelper.get_tag_definition(tag_definition_id, options_for_klient)
  end

  # See com.ning.billing.util.dao.ObjectType in killbill-api
  %w(ACCOUNT ACCOUNT_EMAIL BUNDLE INVOICE PAYMENT INVOICE_ITEM INVOICE_PAYMENT
     SUBSCRIPTION SUBSCRIPTION_EVENT PAYMENT_METHOD REFUND TAG_DEFINITION).each do |object_type|
       define_singleton_method "all_for_#{object_type.downcase}" do |options_for_klient = {}|
         self.all(options_for_klient).delete_if { |tag_definition| !tag_definition.applicable_object_types.include? object_type }
       end
  end

  def save(user = nil, reason = nil, comment = nil, options_for_klient = {})
    Kaui::KillbillHelper.create_tag_definition(self, user, reason, comment, options_for_klient)
    # TODO - we should return the newly created id and update the model
    # @persisted = true
  end

  def destroy(user = nil, reason = nil, comment = nil, options_for_klient = {})
    Kaui::KillbillHelper.delete_tag_definition(@id, user, reason, comment, options_for_klient)
    @persisted = false
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
    @name <=> tag_definition.name
  end
end
