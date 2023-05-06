# frozen_string_literal: true

module Kaui
  class AccountTagsController < Kaui::EngineController
    def index
      cached_options_for_klient = options_for_klient
      account = Kaui::Account.find_by_id_or_key(params.require(:account_id), true, true, cached_options_for_klient)
      tags = account.all_tags(nil, false, 'NONE', cached_options_for_klient)

      formatter = lambda do |tag|
        url_for_object = view_context.url_for_object(tag.object_id, tag.object_type)
        [
          tag.tag_id,
          url_for_object ? view_context.link_to(tag.object_id, url_for_object) : tag.object_id,
          tag.object_type,
          tag.tag_definition_name
        ]
      end
      @tags_json = []
      tags.each { |page| @tags_json << formatter.call(page) }

      @tags_json = @tags_json.to_json
    end

    def edit
      @account_id = params.require(:account_id)

      cached_options_for_klient = options_for_klient
      fetch_tag_names = promise { Kaui::Tag.all_for_account(@account_id, false, 'NONE', cached_options_for_klient).map(&:tag_definition_name).sort }
      fetch_available_tags = promise { Kaui::TagDefinition.all_for_account(cached_options_for_klient) }

      @tag_names = wait(fetch_tag_names)
      @available_tags = wait(fetch_available_tags)
    end

    def update
      account_id = params.require(:account_id)

      tags = []
      params.each do |tag, _tag_name|
        tag_info = tag.split('_')
        next if (tag_info.size != 2) || (tag_info[0] != 'tag')

        tags << tag_info[1]
      end

      Kaui::Tag.set_for_account(account_id, tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_path(account_id), notice: 'Account tags successfully set'
    end
  end
end
