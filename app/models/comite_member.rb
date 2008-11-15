class ComiteMember < ActiveRecord::Base
  
  belongs_to :comite
  belongs_to :user
  
end
