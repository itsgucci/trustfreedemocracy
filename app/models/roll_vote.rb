class RollVote < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :community
  belongs_to :district
  
  belongs_to :roll
  
  def vote_verb
    case vote
    when 0
      "Oppose"
    when 1
      "Approve"
    when "2"
      "Present"
    else
      "No Vote"
    end
  end
  
end
