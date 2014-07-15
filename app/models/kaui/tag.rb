class Kaui::Tag < KillBillClient::Model::Tag

  def is_system_tag?
    Kaui::TagDefinition(:id => tag_definition_id).is_system_tag?
  end

  def <=>(tag)
    tag_definition_name <=> tag.tag_definition_name
  end
end
