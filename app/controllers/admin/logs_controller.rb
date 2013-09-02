class Admin::LogsController < AdminsController

  def index
    @logs = CallLog.order("created_at DESC").page(params[:page])
  end

end