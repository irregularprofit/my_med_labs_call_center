class Schedule < ActiveRecord::Base
  belongs_to :user

  DAYS = [0, 1, 2, 3, 4, 5, 6]
  HOURS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 15, 16, 17 , 18, 19, 20, 21, 22, 23, 24]
  MINS = [0, 15, 30, 45]

  def start_time
    "#{Date::DAYNAMES[self.start_day]}, #{'%02d' % start_hour}:#{'%02d' % start_min}"
  end

  def end_time
    "#{Date::DAYNAMES[self.end_day]}, #{'%02d' % end_hour}:#{'%02d' % end_min}"
  end




end
