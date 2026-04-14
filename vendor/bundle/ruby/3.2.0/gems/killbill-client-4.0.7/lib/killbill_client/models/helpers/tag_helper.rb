module KillBillClient
  module Model
    module TagHelper

      AUTO_PAY_OFF_ID            = '00000000-0000-0000-0000-000000000001'
      AUTO_INVOICING_OFF_ID      = '00000000-0000-0000-0000-000000000002'
      OVERDUE_ENFORCEMENT_OFF_ID = '00000000-0000-0000-0000-000000000003'
      WRITTEN_OFF_ID             = '00000000-0000-0000-0000-000000000004'
      MANUAL_PAY_ID              = '00000000-0000-0000-0000-000000000005'
      TEST_ID                    = '00000000-0000-0000-0000-000000000006'

      def add_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name, 'NONE', options)
        if tag_definition.nil?
          tag_definition             = TagDefinition.new
          tag_definition.name        = tag_name
          tag_definition.description = 'TagDefinition automatically created by the Kill Bill Ruby client library'
          tag_definition             = TagDefinition.create(user, options)
        end

        add_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name, 'NONE', options)
        return nil if tag_definition.nil?

        remove_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def set_tags(tag_definition_ids, user = nil, reason = nil, comment = nil, options = {})
        begin
          current_tag_definition_ids = tags(false, 'NONE', options).map { |tag| tag.tag_definition_id }
        rescue KillBillClient::API::NotFound
          current_tag_definition_ids = []
        end

        tags_to_remove = current_tag_definition_ids - tag_definition_ids
        tags_to_add = tag_definition_ids - current_tag_definition_ids

        remove_tags_from_definition_ids(tags_to_remove.uniq, user, reason, comment, options) unless tags_to_remove.empty?
        add_tags_from_definition_ids(tags_to_add.uniq, user, reason, comment, options) unless tags_to_add.empty?
      end

      def add_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        add_tags_from_definition_ids([tag_definition_id], user, reason, comment, options)
      end

      def remove_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        remove_tags_from_definition_ids([tag_definition_id], user, reason, comment, options)
      end

      def control_tag?(control_tag_definition_id, options)
        tags(false, 'NONE', options).any? do |t|
          t.tag_definition_id == control_tag_definition_id
        end
      end

      module ClassMethods
        def has_tags(url_prefix, id_alias)
          define_method('tags') do |*args|

            included_deleted = args[0] || false
            audit = args[1] || 'NONE'
            options = args[2] || {}

            self.class.get "#{url_prefix}/#{send(id_alias)}/tags",
                           {
                               :includedDeleted => included_deleted,
                               :audit           => audit
                           },
                           options,
                           Tag
          end

          define_method('add_tags_from_definition_ids') do |*args|

            tag_definition_ids = args[0]
            user = args[1]
            reason = args[2]
            comment = args[3]
            options = args[4] || {}

            created_tag = self.class.post "#{url_prefix}/#{send(id_alias)}/tags",
                                          tag_definition_ids,
                                          {},
                                          {
                                              :user    => user,
                                              :reason  => reason,
                                              :comment => comment,
                                          }.merge(options),
                                          Tag
            created_tag.refresh(options)
          end

          define_method('remove_tags_from_definition_ids') do |*args|

            tag_definition_ids = args[0]
            user = args[1]
            reason = args[2]
            comment = args[3]
            options = args[4] || {}

            self.class.delete "#{url_prefix}/#{send(id_alias)}/tags",
                              {},
                              {
                                  :tagDef => tag_definition_ids
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
