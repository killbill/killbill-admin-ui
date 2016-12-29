class Kaui::AdminAllowedUsersController < Kaui::EngineController

  skip_before_filter :check_for_redirect_to_tenant_screen

  def index
    @allowed_users = retrieve_allowed_users_for_current_user
  end

  def new
    @allowed_user = Kaui::AllowedUser.new
  end

  def create
    new_user = Kaui::AllowedUser.new(allowed_user_params)

    existing_user = Kaui::AllowedUser.find_by_kb_username(new_user.kb_username)
    if existing_user
      flash[:error] = "User with name #{new_user.kb_username} already exists!"
      redirect_to admin_allowed_users_path
    else
      new_user.save!
      redirect_to admin_allowed_user_path(new_user.id), :notice => 'User was successfully configured'
    end
  end

  def show
    @allowed_user = Kaui::AllowedUser.find(params.require(:id))
    raise ActiveRecord::RecordNotFound.new("Could not find user #{@allowed_user.id}") unless (current_user.root? || @allowed_user.kb_username == current_user.kb_username)

    tenants_for_current_user = retrieve_tenants_for_current_user
    @tenants = Kaui::Tenant.all.select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }
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
