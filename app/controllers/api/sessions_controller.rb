class Api::SessionsController < Devise::SessionsController
  before_filter :find_user, only: [:get_token, :user_on_call]

  def create
    self.resource = warden.authenticate(auth_options)
    if resource
      sign_in(resource_name, resource)
      return render json: {success: true, slug: resource.slug, name: resource.name, token: resource.get_capability_token}
    else
      return render json: {success: false}
    end
  end

  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    render json: {success: true, redirect: redirect_path}
  end

  def get_token
    if @user
      return render json: {success: true, slug: @user.slug, name: @user.name, token: @user.get_capability_token}
    else
      return render json: {success: false, message: "User not found"}
    end
  end

  def user_on_call
    return render json: {success: (@user && @user.on_call?)}
  end

  private

  def find_user
    @user = User.find_by_slug(params[:slug])
  end
end
