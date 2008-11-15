class Vote < ActiveRecord::Base

  validates_presence_of :user_id
  #validates_uniqueness_of :user_id, :scope => [:voteable_type, :voteable_id]
  
  # NOTE: Votes belong to a user
  belongs_to :user

  def self.find_votes_cast_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  def ==(rhs)
    vote == rhs.vote && voteable_type == rhs.voteable_type && voteable_id == rhs.voteable_id
  end
  
  
end