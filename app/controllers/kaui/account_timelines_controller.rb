class Kaui::AccountTimelinesController < Kaui::EngineController

  def show
    @account = Kaui::Account.find_by_id(params.require(:account_id), false, false, options_for_klient)

    fetch_timeline = lambda { @timeline = Kaui::AccountTimeline.find_by_account_id(@account.account_id, 'FULL', options_for_klient) }
    fetch_invoices = lambda { load_invoices_for_timeline }

    run_in_parallel fetch_timeline, fetch_invoices

    # Lookup all bundle names
    @bundle_names = {}
    @bundle_names_by_invoice_id = {}
    @bundle_keys_by_invoice_id = {}
    @timeline.bundles.each do |bundle|
      load_bundle_name_for_timeline(bundle.external_key)
    end
    @timeline.invoices.each do |invoice|
      @bundle_names_by_invoice_id[invoice.invoice_id] = Set.new
      @bundle_keys_by_invoice_id[invoice.invoice_id] = Set.new
      (invoice.bundle_keys || '').split(',').each do |bundle_key|
        load_bundle_name_for_timeline(bundle_key)
        @bundle_names_by_invoice_id[invoice.invoice_id] << @bundle_names[bundle_key]
        @bundle_keys_by_invoice_id[invoice.invoice_id] << bundle_key
      end
    end

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
    @invoices_by_id = all_invoices.inject({}) { |hsh, invoice| hsh[invoice.invoice_id] = Kaui::Invoice.build_from_raw_invoice(invoice); hsh }
  end
end
