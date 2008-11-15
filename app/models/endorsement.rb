class Endorsement < ActiveRecord::Base
  belongs_to :article, :counter_cache => :focus_count
  belongs_to :user
  
  belongs_to :district
  
  named_scope :active, :conditions => 'ended_at IS NULL'
end