module LegislationsHelper
  
  def time_header(object)
	  if object.closed?
	    return object.votes_for > object.votes_against ? "approved" : "rejected"
	  else
	    return time_left( object.time ) + " until closed"
	  end
  end
  
end
