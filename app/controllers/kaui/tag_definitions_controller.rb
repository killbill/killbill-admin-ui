# frozen_string_literal: true

module Kaui
  class TagDefinitionsController < Kaui::EngineController
    def index
      @tag_definitions = Kaui::TagDefinition.all('NONE', options_for_klient)
    rescue StandardError => e
      flash.now[:error] = "Error while retrieving tag definitions: #{as_string(e)}"
      @tag_definitions = []
    end

    def new
      @tag_definition = Kaui::TagDefinition.new
    end

    def create
      params[:tag_definition][:applicable_object_types] = params[:tag_definition][:applicable_object_types].values unless params[:tag_definition][:applicable_object_types].blank?
      @tag_definition = Kaui::TagDefinition.new(params[:tag_definition])

      begin
        @tag_definition = @tag_definition.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to kaui_engine.tag_definitions_path, notice: 'Tag definition successfully created'
      rescue StandardError => e
        flash.now[:error] = "Error while creating tag definition: #{as_string(e)}"
        render action: :new
      end
    end

    def destroy
      @tag_definition = Kaui::TagDefinition.find_by_id(params[:id], 'NONE', options_for_klient)

      begin
        @tag_definition.delete(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to kaui_engine.tag_definitions_path, notice: 'Tag definition successfully deleted'
      rescue StandardError => e
        flash.now[:error] = "Error while deleting tag definition: #{as_string(e)}"
        render action: :index
      end
    end
  end
end
