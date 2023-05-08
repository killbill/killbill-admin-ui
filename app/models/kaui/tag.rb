# frozen_string_literal: true

module Kaui
  class Tag < KillBillClient::Model::Tag
    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, options)
      else
        find_in_batches(offset, limit, options)
      end
    end

    class << self
      %i[account bundle subscription invoice].each do |model|
        define_method "all_for_#{model}" do |model_id, included_deleted, audit, options|
          instance = Kaui.const_get(model.to_s.camelize).new("#{model}_id".to_sym => model_id)
          instance.tags(included_deleted, audit, options)
        end

        define_method "set_for_#{model}" do |model_id, tags, user, reason, comment, options|
          instance = Kaui.const_get(model.to_s.camelize).new("#{model}_id".to_sym => model_id)
          instance.set_tags(tags, user, reason, comment, options)
        end
      end
    end

    def system_tag?
      Kaui::TagDefinition(id: tag_definition_id).system_tag?
    end

    def <=>(other)
      tag_definition_name.downcase <=> other.tag_definition_name.downcase
    end
  end
end
