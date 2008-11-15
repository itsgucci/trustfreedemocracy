class Comite < ActiveRecord::Base
  
  belongs_to :district
  has_many :comite_members, :dependent => :destroy
  has_many :users, :through => :comite_members
  has_many :comite_stages
  has_many :articles, :through => :comite_stages
  
  def pass(article, time=Time.now)
    comite_stages.find_by_article_id(article.id).update_attributes( :ended_at => time, :status_code => 1 )
  end
  
end
