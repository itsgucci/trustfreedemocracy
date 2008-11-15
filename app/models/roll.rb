class Roll < ActiveRecord::Base
  
  belongs_to :article
  belongs_to :community
  
  has_many :roll_votes
  
end
