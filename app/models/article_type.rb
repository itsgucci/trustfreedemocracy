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
    name == "Plan"
  end
  
  @@list << ArticleType.new(1, "Bill", "A potential governing Law", "B")
  @@list << ArticleType.new(2, "Resolution", "An opportunity for your Democracy to come to an agreement", "R")
  @@list << ArticleType.new(3, "Plan", "Open a topic for discussion, does not enter legislature", "P")
  @@list << ArticleType.new(4, "Simple Resolution", "An opportunity for your Region to come to an agreement", "SR")
  

end