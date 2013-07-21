class AdminsController < ApplicationController
  before_filter :authenticate_user!, :authorize_access
  layout "admin"

  private

  def authorize_access
    redirect_to root_path unless can? :manage, :users
  end

end