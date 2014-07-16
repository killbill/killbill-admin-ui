class Kaui::Tag < KillBillClient::Model::Tag

  def self.find_all_sorted_by_account_id(account_id, included_deleted = false, audit = 'NONE', options = {})
    tags = find_all_by_account_id(account_id, included_deleted, audit, options)
    tags.sort { |tag_a, tag_b| tag_a <=> tag_b }
  end

  def is_system_tag?
    Kaui::TagDefinition(:id => tag_definition_id).is_system_tag?
  end

  def <=>(tag)
    tag_definition_name.downcase <=> tag.tag_definition_name.downcase
  end
end
