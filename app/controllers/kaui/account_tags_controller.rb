class Kaui::AccountTagsController < Kaui::EngineController

  def show
    account_id_or_key = params[:account_id]

    begin
      @account = Kaui::Account::find_by_id_or_key(account_id_or_key, false, false, options_for_klient)
      @tags    = @account.tags(true, 'FULL', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }
    rescue => e
      flash[:error] = "Error while getting tags: #{as_string(e)}"
      redirect_to :back
    end
  end

  def edit
    account_id_or_key = params[:account_id]

    begin
      @account        = Kaui::Account::find_by_id_or_key(account_id_or_key, false, false, options_for_klient)
      @tag_names      = (@account.tags(false, 'NONE', options_for_klient).map { |tag| tag.tag_definition_name }).sort
      @available_tags = Kaui::TagDefinition.all_for_account(options_for_klient)
    rescue => e
      flash[:error] = "Error while editing tags: #{as_string(e)}"
      redirect_to kaui_engine.account_tags_path(:account_id => account_id_or_key)
    end
  end

  def update
    account_id = params[:account_id]

    tags = []
    params.each do |tag, tag_name|
      tag_info = tag.split('_')
      next if tag_info.size != 2 or tag_info[0] != 'tag'
      tags << tag_info[1]
    end

    begin
      account = Kaui::Account.new(:account_id => account_id)
      account.set_tags(tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_tags_path(:account_id => account_id), :notice => 'Account tags successfully set'
    rescue => e
      flash[:error] = "Error while updating tags: #{as_string(e)}"
      redirect_to kaui_engine.account_tags_path(:account_id => account_id)
    end
  end
end
