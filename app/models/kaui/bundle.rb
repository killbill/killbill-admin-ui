class Kaui::Bundle < KillBillClient::Model::Bundle

  def self.find_by_id_or_key(bundle_id_or_key, account_id = nil, options = {})
    if bundle_id_or_key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
      find_by_id(bundle_id_or_key, options)
    else
      if account_id.blank?
        # Return the active one
        find_by_external_key(bundle_id_or_key, options)
      else
        # Return active and inactive ones
        bundles = find_all_by_account_id_and_external_key(account_id, bundle_id_or_key, options)
        get_active_bundle_or_latest_created(bundles)
      end
    end
  end

  def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
    if search_key.present?
      find_in_batches_by_search_key(search_key, offset, limit, options)
    else
      find_in_batches(offset, limit, options)
    end
  end

  private

  def self.get_active_bundle_or_latest_created(bundles)
    return nil if bundles.empty?

    latest_start_date = nil
    latest_bundle     = nil

    bundles.each do |b|
      b.subscriptions.each do |s|
        if s.product_category != 'ADD_ON'
          if latest_start_date.nil? || latest_start_date < s.start_date
            latest_start_date = s.start_date
            latest_bundle     = b
          end

          return b if s.cancelled_date.nil? || s.cancelled_date > Time.now
        end
      end
    end

    latest_bundle
  end
end
