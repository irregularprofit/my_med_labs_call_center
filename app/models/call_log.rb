class CallLog < ActiveRecord::Base
  belongs_to :user

  validates :sid, uniqueness: true
end
