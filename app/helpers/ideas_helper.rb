module IdeasHelper
  
  def time_header(object)
    "created " + object.created_at.strftime('%B %d, %Y')
  end
  
  def link_to_new(text)
    # todo fix so that the user can only add drafts in their district
    logged_in? ? link_to( "Create a Draft", { :action => 'new' }, { :help => "click here to create an idea"} ) : '&nbsp;'
  end
  
end