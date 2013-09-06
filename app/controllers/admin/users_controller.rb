class Admin::UsersController < AdminsController
  def index
    @active_users   = User.non_admin.active
    @inactive_users = User.non_admin.inactive
  end

  def update
    if user.update_attributes(user_params)
      redirect_to admin_users_path, notice: "User updated successfully"
    else
      redirect_to admin_users_path, alert: "we had trouble updating user"
    end
  end

  def destroy
    if user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully"
    else
      redirect_to admin_users_path, alert: "we had trouble deleting user"
    end
  end

  private

  def user_params
    params.require(:user).permit(:approved)
  end

  def user
    @user ||= User.find_by_slug(params[:id])
  end

end