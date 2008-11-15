class BookmarksController < ApplicationController  
  before_filter :get_class_by_name
  
  def create
    object = @object_class.find(params[:id])
    bookmark = current_user.bookmarks.create(:object => object)
    render :update do |page|
      page.insert_html :bottom, :bookmark_list, "<li id='bookmark#{bookmark.id}'>#{ link_to object.name, object } #{link_to_remote 'x', :url => bookmark_url(bookmark), :method => :delete}</li>"
      page.hide("bookmark#{ bookmark.id }")
      page.visual_effect(:appear, "bookmark#{ bookmark.id }")
    end
  end
  
  def destroy
    bookmark = Bookmark.find(params[:id])
    bookmark.destroy
    render :update do |page|
      page.visual_effect(:fade, 'bookmark' + params[:id])
      page.delay do
        page.remove("boomark#{ params[:id] }")
      end
    end
  end
  
  protected
  # Gets the rateable class based on the params[:rateable_type]  
  def get_class_by_name
    if params[:object_type]
      bad_class = false  
      begin  
        @object_class = Module.const_get(params[:object_type].capitalize.singularize)  
      rescue NameError
        # The user is messing with the content_class...
        bad_class = true
      end   
      
      # This means the user is doing something funky...naughty naughty...  
      if bad_class
        redirect_to home_url
        return false
      end 
    
      true
    else
      false
    end
  end
  
end
