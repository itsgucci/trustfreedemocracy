class Legislation < ActiveRecord::Base
  
  belongs_to :article
  belongs_to :district
    
  def number
    "O." + article.id.to_s
  end
  
  def support
    self.votes_count
  end
  def support_verb
    "vote"
  end
  
  def content
    #RedCloth.new().to_html
    strip_tags full_text
  end
  
  def closed?
    self.closing_time < Time.new
  end
  
  def time
    self.closing_time
  end
  def time_verb
    "closes in"
  end
  
  
  private
  def strip_tags(string)
    string.gsub(/<\/?[^>]*>/, "")
  end
  
end
