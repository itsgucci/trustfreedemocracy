class ArticleType  
  
  attr_reader :id, :name, :description, :short_name
  
  @@list = []
  
  def initialize(id, name, description, shortname)
    @id = id
    @name = name
    @description = description
    @short_name = shortname
  end
  
  def self.list
    @@list
  end
  
  def bill?
    name == "Bill"
  end
  def resolution?
    name == "Resolution"
  end
  def concern?
    name == "Concern"
  end
  
  @@list << ArticleType.new(1, "Bill", "Change how your community is spending your tax dollars", "B")
  @@list << ArticleType.new(2, "Resolution", "Change the laws, not money related", "R")
  @@list << ArticleType.new(3, "Concern", "Open a topic for discussion, not voted on", "C")
  

end