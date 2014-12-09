class Meetup < ActiveRecord::Base
  # belongs_to :user
  has_many :attendees
  has_many :comments
  has_many :users, through: :attendees
end
