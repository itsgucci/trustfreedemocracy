class MailingList < ActiveRecord::Base
  
  validates_presence_of :email, :zip
  
  validates_uniqueness_of :email 
  
end
