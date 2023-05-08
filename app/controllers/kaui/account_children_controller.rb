# frozen_string_literal: true

module Kaui
  class AccountChildrenController < Kaui::EngineController
    def index
      # check that the required parent account id is provided and get its data

      @account = Kaui::Account.find_by_id(params.require(:account_id), false, false, options_for_klient)
    rescue KillBillClient::API::NotFound
      flash[:error] = "Invalid parent account id supplied #{params.require(:account_id)}"
      redirect_to kaui_engine.home_path and return
    end

    # It will fetch all the children. It use the paginate to fetch all children as permitting for future exchange
    # when killbill account/{account_id}/children endpoint includes offset and limit parameters.
    def pagination
      cached_options_for_klient = options_for_klient
      searcher = lambda do |parent_account_id, _offset, _limit|
        Kaui::Account.find_children(parent_account_id, true, true, 'NONE', cached_options_for_klient)
      end

      data_extractor = lambda do |account_child, column|
        [
          account_child.name,
          account_child.account_id,
          account_child.external_key,
          account_child.account_balance,
          account_child.city,
          account_child.country
        ][column]
      end

      formatter = lambda do |account_child|
        [
          view_context.link_to(account_child.account_id, account_path(account_child.account_id)),
          account_child.external_key,
          view_context.humanized_money_with_symbol(account_child.balance_to_money)
        ]
      end

      paginate searcher, data_extractor, formatter
    end
  end
end
