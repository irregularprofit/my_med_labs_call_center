class Admin::MonthlyTotalsController < AdminsController
  NUM_OF_MONTH_BACK_TO_SHOW = 6

  def index
    @monthly_totals = {}
    ((NUM_OF_MONTH_BACK_TO_SHOW - 1).downto(0)).each do |month_offset|
      date = Time.now.beginning_of_month - month_offset.month
      @monthly_totals[date.strftime("%B-%Y")] = MonthlyTotal.where(date: date)
    end
  end

end
