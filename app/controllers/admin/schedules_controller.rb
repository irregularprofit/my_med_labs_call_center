class Admin::SchedulesController < AdminsController
  def index
    @schedules = Schedule.all
    @unscheduled = User.joins("LEFT JOIN schedules ON schedules.user_id = users.id").
      where('schedules.id is NULL')
  end

  def create
    @schedule = Schedule.new(schedule_params)
    @schedule.enabled = true
    @schedule.save
    redirect_to admin_schedules_url
  end

  def update
    if schedule.update_attributes(schedule_params)
      redirect_to admin_schedules_path, notice: "Schedule updated successfully"
    else
      redirect_to admin_schedules_path, alert: "We had trouble updating schedule"
    end
  end

  def destroy
    if schedule.destroy
      redirect_to admin_schedules_path, notice: "Schedule destroyed successfully"
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(
      :start_day, :end_day, :start_hour,
      :end_hour, :start_min, :end_min,
      :user_id, :enabled
    )
  end

  def schedule
    @schedule ||= Schedule.find_by_id(params[:id])
  end

end
