# class KauiPhoneValid
#   include ActiveModel::Validations
#   attr_accessor :phone
#   validates :phone, format: { with: /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/i, message: 'invalid phone'}
# end
