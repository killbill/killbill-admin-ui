# frozen_string_literal: true

module Kaui
  class AccountBlockingStatesController < Kaui::EngineController
    def index
      options = options_for_klient
      @account = Kaui::Account.find_by_id_or_key(params.require(:account_id), false, false, options)
      blocking_states = @account.blocking_states(nil, nil, 'NONE', options)

      formatter = lambda do |bs|
        object_type = bs.type == 'SUBSCRIPTION_BUNDLE' ? 'BUNDLE' : bs.type
        url = view_context.url_for_object(bs.blocked_id, object_type)
        [
          object_type,
          url ? view_context.link_to(bs.blocked_id, url) : bs.blocked_id,
          bs.service,
          bs.state_name,
          [('Change' if bs.is_block_change), ('Entitlement' if bs.is_block_entitlement), ('Billing' if bs.is_block_billing)].compact.join(', '),
          bs.effective_date
        ]
      end
      @blocking_states_json = blocking_states.map { |bs| formatter.call(bs) }.to_json
    end
  end
end
