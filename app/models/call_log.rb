class CallLog < ActiveRecord::Base
  belongs_to :user

  validates :sid, uniqueness: true
  validates :duration, numericality: { greater_than: 0}
end
