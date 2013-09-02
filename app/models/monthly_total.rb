class MonthlyTotal < ActiveRecord::Base
  belongs_to :user
  has_many :call_logs

  after_initialize :init

  private

  def init
    self.duration ||= 0
  end

end