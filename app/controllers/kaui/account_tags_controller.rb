class Kaui::AccountTagsController < ApplicationController

  def show
    account_id = params[:id]
    if account_id.present?
      tags = Kaui::KillbillHelper::get_tags_for_account(account_id)
    else
      flash[:error] = "No account id given"
    end
  end

  def edit
    @account_id = params[:account_id]
    @available_tags = Kaui::KillbillHelper::get_tag_definitions.sort {|tag_a, tag_b| tag_a.name.downcase <=> tag_b.name.downcase }

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @tags = Kaui::KillbillHelper::get_tags_for_account(@account.account_id)
  end

  def update
    account = Kaui::KillbillHelper::get_account(params[:account_id])
    tags = params[:tags]

    Kaui::KillbillHelper::set_tags_for_account(account.account_id, tags)
    redirect_to Kaui.account_home_path.call(account.external_key)
  end

end
