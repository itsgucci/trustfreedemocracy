class ArticlesSupporter < ActiveRecord::Base
  
  belongs_to :article, :counter_cache => :support_count
  belongs_to :user
  
  
end