class RollVote < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :community
  belongs_to :district
  
  belongs_to :roll
  
end
