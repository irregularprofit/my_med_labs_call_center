class Api::SessionsController < Devise::SessionsController
  acts_as_token_authentication_handler_for User, only: [:get_token, :user_on_call, :get_active_agents]

  def create
    self.resource = warden.authenticate(auth_options)
    if resource
      sign_in(resource_name, resource)
      return render json: {
        success: true,
        slug: resource.slug,
        name: resource.name,
        token: resource.get_capability_token,
        auth_token: resource.authentication_token
      }
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
    if current_user
      return render json: {
        success: true,
        slug: current_user.slug,
        name: current_user.name,
        token: current_user.get_capability_token,
        auth_token: current_user.authentication_token
      }
    else
      return render json: {success: false, message: "User not found"}
    end
  end

  def user_on_call
    return render json: {success: (current_user && current_user.on_call?)}
  end

  def get_active_agents
    users = User.where("id != ?", current_user.id).all.select{|x| x.on_call? }
    return render json: {success: true, users: users.as_json}
  end
end
