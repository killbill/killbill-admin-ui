class Kaui::BundleTagsController < Kaui::EngineController

  def show
    bundle_id_or_key = params[:bundle_id]
    account_id       = params[:account_id]

    begin
      @bundle  = Kaui::Bundle::find_by_id_or_key(bundle_id_or_key, account_id, options_for_klient)
      @account = Kaui::Account::find_by_id_or_key(@bundle.account_id, false, false, options_for_klient)
      @tags    = @bundle.tags(true, 'FULL', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }
    rescue => e
      flash[:error] = "Error while getting tags: #{as_string(e)}"
      redirect_to :back
    end
  end

  def edit
    bundle_id_or_key = params[:bundle_id]
    account_id       = params[:account_id]

    begin
      @bundle         = Kaui::Bundle::find_by_id_or_key(bundle_id_or_key, account_id, options_for_klient)
      @tag_names      = (@bundle.tags(false, 'NONE', options_for_klient).map { |tag| tag.tag_definition_name }).sort
      @available_tags = Kaui::TagDefinition.all_for_bundle(options_for_klient)
    rescue => e
      flash[:error] = "Error while editing tags: #{as_string(e)}"
      redirect_to kaui_engine.bundle_tags_path(:bundle_id => bundle_id_or_key)
    end
  end

  def update
    bundle_id = params[:bundle_id]

    tags = []
    params.each do |tag, tag_name|
      tag_info = tag.split('_')
      next if tag_info.size != 2 or tag_info[0] != 'tag'
      tags << tag_info[1]
    end

    begin
      bundle = Kaui::Bundle.new(:bundle_id => bundle_id)
      bundle.set_tags(tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.bundle_tags_path(:bundle_id => bundle_id), :notice => 'Bundle tags successfully set'
    rescue => e
      flash[:error] = "Error while updating tags: #{as_string(e)}"
      redirect_to kaui_engine.bundle_tags_path(:bundle_id => bundle_id)
    end
  end
end
