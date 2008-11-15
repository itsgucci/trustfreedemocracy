module ProposalsHelper
  
  def time_header(object)
	  if object.closed?
	    return "approved"
	  else
	    return "finalized " + time_left( object.time ) + " ago"
	  end
  end
  
  def link_to_new(text)
    '&nbsp;'
  end
  
end
