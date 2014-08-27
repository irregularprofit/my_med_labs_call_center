class Api::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)
    if !resource
      return render json: {success: false}
    else
      sign_in(resource_name, resource)
      return render json: {success: true, slug: resource.slug, name: resource.name}
    end
  end

  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    render json: {success: true, redirect: redirect_path}
  end
end
