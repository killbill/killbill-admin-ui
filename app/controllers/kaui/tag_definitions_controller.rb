module Kaui
  class TagDefinitionsController < Kaui::EngineController
    # GET /tag_definitions
    # GET /tag_definitions.json
    def index
      begin
        @tag_definitions = TagDefinition.all(options_for_klient)
      rescue => e
        flash.now[:error] = "Error while retrieving tag definitions: #{as_string(e)}"
        @tag_definitions = []
      end

      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @tag_definitions }
      end
    end

    # GET /tag_definitions/1
    # GET /tag_definitions/1.json
    def show
      @tag_definition = TagDefinition.find(params[:id], options_for_klient)

      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @tag_definition }
      end
    end

    # GET /tag_definitions/new
    # GET /tag_definitions/new.json
    def new
      @tag_definition = TagDefinition.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @tag_definition }
      end
    end

    # GET /tag_definitions/1/edit
    def edit
      @tag_definition = TagDefinition.find(params[:id], options_for_klient)
    end

    # POST /tag_definitions
    # POST /tag_definitions.json
    def create
      @tag_definition = TagDefinition.new(params[:tag_definition])

      respond_to do |format|
        if @tag_definition.save(current_user, params[:reason], params[:comment], options_for_klient)
          format.html { redirect_to @tag_definition, :notice => 'Tag definition was successfully created.' }
          format.json { render :json => @tag_definition, :status => :created, :location => @tag_definition }
        else
          format.html { render :action => "new" }
          format.json { render :json => @tag_definition.errors, :status => :unprocessable_entity }
        end
      end
    end

    # PUT /tag_definitions/1
    # PUT /tag_definitions/1.json
    def update
      @tag_definition = TagDefinition.find(params[:id], options_for_klient)

      respond_to do |format|
        if @tag_definition.update_attributes(params[:tag_definition])
          format.html { redirect_to @tag_definition, :notice => 'Tag definition was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @tag_definition.errors, :status => :unprocessable_entity }
        end
      end
    end

    # DELETE /tag_definitions/1
    # DELETE /tag_definitions/1.json
    def destroy
      @tag_definition = TagDefinition.find(params[:id], options_for_klient)
      @tag_definition.destroy(current_user, params[:reason], params[:comment], options_for_klient)

      respond_to do |format|
        format.html { redirect_to tag_definitions_url, :notice => 'Tag definition was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end
end
