class Kaui::TagsController < Kaui::EngineController

  def index
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    search_key = params[:sSearch]
    if search_key.present?
      tags = Kaui::KillbillHelper::search_tags(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      tags = Kaui::KillbillHelper::get_tags(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = tags.pagination_total_nb_records
    json[:iTotalRecords] = tags.pagination_max_nb_records

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