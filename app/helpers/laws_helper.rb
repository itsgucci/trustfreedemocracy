module LawsHelper
  
  def time_header(object)
	  if object.closed?
	    return object.votes_for > object.votes_against ? "approved" : "rejected"
	  else
	    return "closed " + time_left( object.time ) + " ago"
	  end
  end
  
  def link_to_new(text)
    "&nbsp;"
  end
  
end