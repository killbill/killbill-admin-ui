class Kaui::Tag < Kaui::Base

  define_attr :tag_definition_id
  define_attr :tag_definition_name
  define_attr :audit_logs

  def is_system_tag?
    Kaui::TagDefinition(:id => tag_definition_id).is_system_tag?
  end

  def <=>(tag)
    @tag_definition_name <=> tag.tag_definition_name
  end
end