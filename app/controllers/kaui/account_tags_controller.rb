class Kaui::AccountTagsController < Kaui::EngineController

  def edit
    account_id_or_key = params.require(:account_id)

    @account = Kaui::Account::find_by_id_or_key(account_id_or_key, false, false, options_for_klient)
    @tag_names = (@account.tags(false, 'NONE', options_for_klient).map { |tag| tag.tag_definition_name }).sort
    @available_tags = Kaui::TagDefinition.all_for_account(options_for_klient)
  end

  def update
    account_id = params.require(:account_id)

    tags = []
    params.each do |tag, tag_name|
      tag_info = tag.split('_')
      next if tag_info.size != 2 or tag_info[0] != 'tag'
      tags << tag_info[1]
    end

    account = Kaui::Account.new(:account_id => account_id)
    account.set_tags(tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_path(account_id), :notice => 'Account tags successfully set'
  end
end
