class Kaui::BundleTagsController < Kaui::EngineController

  def edit
    @bundle_id = params.require(:bundle_id)
    @tag_names = (Kaui::Tag.all_for_bundle(@bundle_id, false, 'NONE', options_for_klient).map { |tag| tag.tag_definition_name }).sort
    @available_tags = Kaui::TagDefinition.all_for_bundle(options_for_klient)
  end

  def update
    account_id = params.require(:account_id)
    bundle_id = params.require(:bundle_id)

    tags = []
    params.each do |tag, tag_name|
      tag_info = tag.split('_')
      next if tag_info.size != 2 or tag_info[0] != 'tag'
      tags << tag_info[1]
    end

    Kaui::Tag.set_for_bundle(bundle_id, tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_bundles_path(account_id), :notice => 'Bundle tags successfully set'
  end
end
