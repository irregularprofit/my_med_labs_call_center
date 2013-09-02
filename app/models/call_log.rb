class CallLog < ActiveRecord::Base
  belongs_to :user
  paginates_per 5

  validates :sid, uniqueness: true
  validates :duration, numericality: { greater_than: 0}
end
