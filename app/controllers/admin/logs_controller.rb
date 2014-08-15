class Admin::LogsController < AdminsController

  def index
    @logs = CallLog.order("start_time DESC").page(params[:page] || 1).per(20)
  end

end
