class Kaui::TagsController < Kaui::EngineController

  def index
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      Kaui::Tag.list_or_search(search_key, offset, limit, options_for_klient)
    end

    data_extractor = lambda do |tag, column|
      [
          tag.tag_id,
          tag.object_type,
          tag.tag_definition_name
      ][column]
    end

    formatter = lambda do |tag|
      [
          tag.tag_id,
          tag.object_type,
          tag.tag_definition_name
      ]
    end

    paginate searcher, data_extractor, formatter
  end
end
