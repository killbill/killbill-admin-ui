class Kaui::Tag < KillBillClient::Model::Tag

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, options)
    else
      find_in_batches(offset, limit, options)
    end
  end

  def is_system_tag?
    Kaui::TagDefinition(:id => tag_definition_id).is_system_tag?
  end

  def <=>(tag)
    tag_definition_name.downcase <=> tag.tag_definition_name.downcase
  end
end
