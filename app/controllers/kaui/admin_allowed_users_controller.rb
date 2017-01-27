class Kaui::AdminAllowedUsersController < Kaui::EngineController

  skip_before_filter :check_for_redirect_to_tenant_screen

  def index
    @allowed_users = retrieve_allowed_users_for_current_user
  end

  def new
    @allowed_user = Kaui::AllowedUser.new
    @roles = []
  end

  def create
    @allowed_user = Kaui::AllowedUser.new(allowed_user_params)

    existing_user = Kaui::AllowedUser.find_by_kb_username(@allowed_user.kb_username)
    if existing_user
      flash[:error] = "User with name #{@allowed_user.kb_username} already exists!"
      render :new and return
    else
      roles = params[:roles].split(',')

      # Create locally and in KB
      @allowed_user.create_in_kb!(params.require(:password), roles, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.admin_allowed_user_path(@allowed_user.id), :notice => 'User was successfully configured'
    end
  end

  def show
    @allowed_user = Kaui::AllowedUser.find(params.require(:id))
    raise ActiveRecord::RecordNotFound.new("Could not find user #{@allowed_user.id}") unless (current_user.root? || @allowed_user.kb_username == current_user.kb_username)

    @roles = Kaui::UserRole.find_roles_by_username(@allowed_user.kb_username, options_for_klient).map(&:presence).compact || []

    tenants_for_current_user = retrieve_tenants_for_current_user
    @tenants = Kaui::Tenant.all.select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }
  end

  def edit
    @allowed_user = Kaui::AllowedUser.find(params.require(:id))

    @roles = Kaui::UserRole.find_roles_by_username(@allowed_user.kb_username, options_for_klient).map(&:presence).compact || []
  end

  def update
    @allowed_user = Kaui::AllowedUser.find(params.require(:id))

    @allowed_user.description = params[:allowed_user][:description].presence

    @allowed_user.update_in_kb!(params[:password].presence,
                                params[:roles].presence.split(','),
                                current_user.kb_username,
                                params[:reason],
                                params[:comment],
                                options_for_klient)

    redirect_to kaui_engine.admin_allowed_user_path(@allowed_user.id), :notice => 'User was successfully updated'
  end

  def destroy
    allowed_user = Kaui::AllowedUser.find(params.require(:id))

    if allowed_user
      # Delete locally and in KB
      allowed_user.destroy_in_kb!(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.admin_allowed_users_path, :notice => 'User was successfully deleted'
    else
      flash[:error] = "User #{params.require(:id)} not found"
      redirect_to kaui_engine.admin_allowed_users_path
    end
  end

  def add_tenant
    allowed_user = Kaui::AllowedUser.find(params.require(:allowed_user).require(:id))

    if !current_user.root?
      redirect_to admin_allowed_user_path(allowed_user.id), :alert => 'Only the root user can set tenants for user'
      return
    end

    tenants = []
    params.each do |tenant, _|
      tenant_info = tenant.split('_')
      next if tenant_info.size != 2 or tenant_info[0] != 'tenant'
      tenants << tenant_info[1]
    end

    tenants_for_current_user = retrieve_tenants_for_current_user
    tenants = (Kaui::Tenant.where(:id => tenants).select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }).map(&:id)

    allowed_user.kaui_tenant_ids = tenants

    redirect_to admin_allowed_user_path(allowed_user.id), :notice => 'Successfully set tenants for user'
  end

  private

  def allowed_user_params
    allowed_user = params.require(:allowed_user)
    allowed_user.require(:kb_username)
    allowed_user
  end
end
