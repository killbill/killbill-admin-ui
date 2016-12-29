class Kaui::AdminController < Kaui::EngineController

  skip_before_filter :check_for_redirect_to_tenant_screen

  def index
    @clock = Kaui::Admin.get_clock(nil, options_for_klient)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def set_clock
    if params[:commit] == 'Submit'
      current_datetime = DateTime.parse(Kaui::Admin.get_clock(nil, options_for_klient)['currentUtcTime'])
      new_local_date = Date.parse(params[:new_date])
      new_datetime = DateTime.new(new_local_date.year, new_local_date.month, new_local_date.day, current_datetime.hour, current_datetime.min, current_datetime.sec, 'Z').to_s
      msg = "Clock was successfully updated to #{new_datetime}"
    else
      new_datetime = nil
      msg = 'Clock was successfully reset'
    end
    Kaui::Admin.set_clock(new_datetime, nil, options_for_klient)
    redirect_to admin_path, :notice => msg
  end
end
