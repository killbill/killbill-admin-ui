class Kaui::Tag < KillBillClient::Model::Tag

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, options)
    else
      find_in_batches(offset, limit, options)
    end
  end

  class << self
    [:account, :bundle, :subscription].each do |model|
      define_method "all_for_#{model.to_s}" do |model_id, included_deleted, audit, options|
        instance = Kaui.const_get(model.to_s.camelize).new("#{model.to_s}_id".to_sym => model_id)
        instance.tags(included_deleted, audit, options)
      end

      define_method "set_for_#{model.to_s}" do |model_id, tags, user, reason, comment, options|
        instance = Kaui.const_get(model.to_s.camelize).new("#{model.to_s}_id".to_sym => model_id)
        instance.set_tags(tags, user, reason, comment, options)
      end
    end
  end

  def is_system_tag?
    Kaui::TagDefinition(:id => tag_definition_id).is_system_tag?
  end

  def <=>(tag)
    tag_definition_name.downcase <=> tag.tag_definition_name.downcase
  end
end
