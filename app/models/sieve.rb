class Sieve
  
  def initialize(session)
    @session = session
    @session[:sieve] ||= []
  end
  
  def tags
    @session[:sieve]
  end
  
  def add(tag)
    @session[:sieve] << tag.id
  end

  def include?(tag)
    @session[:sieve].include?(tag.id)
  end
  
  def remove(tag)
    @session[:sieve].delete tag.id
  end
  
  def clear
    @session[:sieve].empty
  end
end