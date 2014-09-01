class Api::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)
    if resource
      sign_in(resource_name, resource)
      token = generate_twilio_token(resource)

      return render json: {success: true, slug: resource.slug, name: resource.name, token: token}
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
    user = User.find_by_slug(params[:slug])

    if user
      token = generate_twilio_token(user)
      return render json: {success: true, slug: user.slug, name: user.name, token: token}
    else
      return render json: {success: false, message: "User not found"}
    end
  end

  def user_on_call
    user = User.find_by_slug(params[:slug])

    return render json: {success: (user && user.on_call?)}
  end

  private

  def generate_twilio_token(user)
    capability = Twilio::Util::Capability.new ACCOUNT_SID, AUTH_TOKEN

    # Create an application sid at twilio.com/user/account/apps and use it here
    capability.allow_client_outgoing APP_TOKEN
    capability.allow_client_incoming user.slug
    capability.generate
  end
end
