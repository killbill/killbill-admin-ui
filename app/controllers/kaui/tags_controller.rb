class Kaui::TagsController < Kaui::EngineController

  def index
  end

  def pagination
    search_key = params[:sSearch]
    offset     = params[:iDisplayStart] || 0
    limit      = params[:iDisplayLength] || 10

    tags = Kaui::Tag.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho                => params[:sEcho],
        :iTotalRecords        => tags.pagination_max_nb_records,
        :iTotalDisplayRecords => tags.pagination_total_nb_records,
        :aaData               => []
    }

    tags.each do |tag|
      json[:aaData] << [
          tag.tag_id,
          tag.object_type,
          tag.tag_definition_name,
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end
end
