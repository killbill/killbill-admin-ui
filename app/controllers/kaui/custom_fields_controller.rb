class Kaui::CustomFieldsController < Kaui::EngineController

  def index
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    search_key = params[:sSearch]
    if search_key.present?
      custom_fields = Kaui::KillbillHelper::search_custom_fields(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      custom_fields = Kaui::KillbillHelper::get_custom_fields(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = custom_fields.pagination_total_nb_records
    json[:iTotalRecords] = custom_fields.pagination_max_nb_records

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