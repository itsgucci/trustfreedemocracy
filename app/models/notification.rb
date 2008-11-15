class Notification < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :from_user, :class_name => "User", :foreign_key => 'from_user_id'
  
  NEW = 1
  HIDDEN = 2
  
  def self.unread
    find(:all, :conditions => "status_code = #{NEW}", :order => "created_at DESC")
  end
  
  def hide!
    update_attribute('status_code', HIDDEN)
  end
  
end
