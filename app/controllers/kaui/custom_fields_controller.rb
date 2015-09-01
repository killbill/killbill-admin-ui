class Kaui::CustomFieldsController < Kaui::EngineController

  def index
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      Kaui::CustomField.list_or_search(search_key, offset, limit, options_for_klient)
    end

    data_extractor = lambda do |custom_field, column|
      [
          custom_field.name,
          custom_field.value
      ][column]
    end

    formatter = lambda do |custom_field|
      [
          custom_field.name,
          custom_field.value
      ]
    end

    paginate searcher, data_extractor, formatter
  end
end
