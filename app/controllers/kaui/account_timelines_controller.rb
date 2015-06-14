class Kaui::AccountTimelinesController < Kaui::EngineController

  def index
  end

  def show
    @account_id = params[:id]

    begin
      @account  = Kaui::Account.find_by_id(@account_id, false, false, options_for_klient)
      @timeline = Kaui::AccountTimeline.find_by_account_id(@account_id, 'MINIMAL', options_for_klient)
    rescue => e
      flash[:error] = "Could not load the account timeline for #{@account_id}: #{as_string(e)}"
      render :action => :index and return
    end

    # Lookup all bundle names
    @bundle_names               = {}
    @bundle_names_by_invoice_id = {}
    @bundle_keys_by_invoice_id  = {}
    @timeline.bundles.each do |bundle|
      load_bundle_name_for_timeline(bundle.external_key)
    end
    @timeline.invoices.each do |invoice|
      @bundle_names_by_invoice_id[invoice.invoice_id] = Set.new
      @bundle_keys_by_invoice_id[invoice.invoice_id]  = Set.new
      (invoice.bundle_keys || '').split(',').each do |bundle_key|
        load_bundle_name_for_timeline(bundle_key)
        @bundle_names_by_invoice_id[invoice.invoice_id] << @bundle_names[bundle_key]
        @bundle_keys_by_invoice_id[invoice.invoice_id] << bundle_key
      end
    end

    # Lookup all invoices
    load_invoices_for_timeline

    if params.has_key?(:external_key)
      @selected_bundle = @bundle_names[params[:external_key]]
    end
  end

  private

  def load_bundle_name_for_timeline(bundle_key)
    @bundle_names[bundle_key] ||= Kaui.bundle_key_display_string.call(bundle_key)
  end

  def load_invoices_for_timeline
    all_invoices = @account.invoices(true, options_for_klient)
    return {} if all_invoices.nil? || all_invoices.empty?

    # Convert into Kaui::Invoice to benefit from additional methods xxx_to_money
    @invoices_by_id = all_invoices.inject({}) {|hsh, invoice| hsh[invoice.invoice_id] = Kaui::Invoice.new(invoice); hsh}
  end

  def load_invoice_id_for_timeline(invoice_id)
    return if invoice_id.blank? or @invoices_by_id.has_key?(invoice_id)

    begin
      @invoices_by_id[invoice_id] = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)
    rescue => e
      flash.now[:error] = "Could not get invoice information for the timeline #{@account_id}: #{as_string(e)}"
    end
  end
end
