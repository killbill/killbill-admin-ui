module KillBillClient
  module Model
    module CustomFieldHelper

      module ClassMethods
        def has_custom_fields(url_prefix, id_alias)
          define_method('custom_fields') do |*args|

            audit = args[0] || 'NONE'
            options = args[1] || {}

            self.class.get "#{url_prefix}/#{send(id_alias)}/customFields",
                           {
                               :audit => audit
                           },
                           options,
                           CustomField
          end

          define_method('add_custom_field') do |*args|

            custom_fields = args[0]
            user = args[1]
            reason = args[2]
            comment = args[3]
            options = args[4] || {}

            body         = custom_fields.is_a?(Enumerable) ? custom_fields : [custom_fields]
            custom_field = self.class.post "#{url_prefix}/#{send(id_alias)}/customFields",
                                           body.to_json,
                                           {},
                                           {
                                               :user    => user,
                                               :reason  => reason,
                                               :comment => comment,
                                           }.merge(options),
                                           CustomField
            custom_field.refresh(options)
          end

          define_method('modify_custom_field') do |*args|

            custom_fields = args[0]
            user = args[1]
            reason = args[2]
            comment = args[3]
            options = args[4] || {}

            body         = custom_fields.is_a?(Enumerable) ? custom_fields : [custom_fields]
            custom_field = self.class.put "#{url_prefix}/#{send(id_alias)}/customFields",
                                           body.to_json,
                                           {},
                                           {
                                               :user    => user,
                                               :reason  => reason,
                                               :comment => comment,
                                           }.merge(options),
                                           CustomField
            custom_field.refresh(options)
          end

          define_method('remove_custom_field') do |*args|

            custom_fields = args[0]
            user = args[1]
            reason = args[2]
            comment = args[3]
            options = args[4] || {}

            custom_fields_param = custom_fields.respond_to?(:join) ? custom_fields.join(",") : custom_fields
            self.class.delete "#{url_prefix}/#{send(id_alias)}/customFields",
                              {},
                              {
                                  :customField => custom_fields_param
                              },
                              {
                                  :user    => user,
                                  :reason  => reason,
                                  :comment => comment,
                              }.merge(options)
          end
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
