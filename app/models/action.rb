class Action < ActiveRecord::Base

  belongs_to :article
  belongs_to :district
  belongs_to :community

  validates_presence_of :article_id, :on => :save, :message => "fundamentally required"
  #validates_presence_of :district_id, :on => :save, :message => "fundamentally required"
  
  named_scope :certified, lambda {{:conditions => ["certified = ?", (certification_filter? ? 1 : nil)]}}
  
  @@crazy = 
  "Introduced to Community
  Revised by Author
  Finalized
  Introduced to House
  Passed House 1st Reading
  Passed House 2nd Reading
  Passed House 3rd Reading
  Passed House Final Reading
  House Amends Motion
  House Agrees with Senate
  House Disagrees with Senate
  Introduced to Senate
  Passed Senate 1st Reading
  Passed Senate 2nd Reading
  Passed Senate 3rd Reading
  Passed Senate Final Reading
  Senate Amends Motion
  Senate Agrees with House
  Senate Disagrees with House
  Referred to Comite
  Reported on by Comite
  Referred to Conference
  Reported on by Conference
  ToExec
  Signed
  Vetoed
  Enacted
  Killed".to_a.map { |x| x.strip }

end
