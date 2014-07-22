class Kaui::CustomFieldsController < Kaui::EngineController

  def index
  end

  def pagination
    search_key = params[:sSearch]
    offset     = params[:iDisplayStart] || 0
    limit      = params[:iDisplayLength] || 10

    custom_fields = Kaui::CustomField.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho                => params[:sEcho],
        :iTotalRecords        => custom_fields.pagination_max_nb_records,
        :iTotalDisplayRecords => custom_fields.pagination_total_nb_records,
        :aaData               => []
    }

    custom_fields.each do |custom_field|
      json[:aaData] << [
          custom_field.name,
          custom_field.value
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end
end
