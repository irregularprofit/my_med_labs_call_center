class CallLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :monthly_total
  paginates_per 5

  validates :sid, uniqueness: true
  validates :duration, numericality: { greater_than: 0}

  before_save :set_monthly_total

  private

  def set_monthly_total
    date          = Time.now.beginning_of_month
    monthly_total = MonthlyTotal.where(user: user, date: date).first || 
                    MonthlyTotal.new(user: user, date: date)
    monthly_total.duration += duration
    self.monthly_total = monthly_total if monthly_total.save
  end

end