class Kaui::TagDefinition < Kaui::Base

  define_attr :id
  define_attr :name
  define_attr :description

  def self.all
    Kaui::KillbillHelper.get_tag_definitions
  end

  def self.find(tag_definition_id)
    Kaui::KillbillHelper.get_tag_definition(tag_definition_id)
  end

  def save
    Kaui::KillbillHelper.create_tag_definition(self)
    # TODO - we should return the newly created id and update the model
    # @persisted = true
  end

  def destroy
    Kaui::KillbillHelper.delete_tag_definition(@id)
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
    @name.downcase <=> tag_definition.name.downcase
  end
end