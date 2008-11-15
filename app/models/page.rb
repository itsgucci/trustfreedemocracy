class Page < ActiveRecord::Base
  
  has_many :page_relationships
  
  #acts_as_versioned
  
  
end
