class RatingsController < ApplicationController  
  before_filter :get_class_by_name  
  before_filter :login_required, :only => ['rate']
      
  def rate  
    return unless logged_in?  
      
    rateable = @rateable_class.find(params[:id])  
      
    # Delete the old ratings for current user  
    Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @rateable_class.base_class.to_s, params[:id], current_user.id])  
    rateable.add_rating Rating.new(:rating => params[:rating], :user_id => current_user.id)  
          
    render :update do |page|  
      page.replace_html "star-ratings-block-#{rateable.id}", :partial => "rate", :locals => { :asset => rateable }  
      page.visual_effect :highlight, "star-ratings-block-#{rateable.id}"  
    end  
  end
  
  def comment
    #return unless logged_in?
    
    commentable = @rateable_class.find(params[:id]) 
    
    comment = Comment.new(params[:comment])
    comment.user_id = current_user.id if logged_in?
    commentable.add_comment comment
    # reload the comment so we can get the id
    comment.reload
    
    
    render :update do |page|  
      page.insert_html :bottom, "comments#{ commentable.id }", :partial => "/comments/comment_and_reply", :locals => { :comment => comment }  
      page.visual_effect :highlight, "comment#{ comment.id }"  
      page.remove "comment_write#{ commentable.id }"
    end
  end
  
  def add_report
    commentable = @rateable_class.find(params[:id]) 
    
    comment = Comment.new(params[:comment])
    comment.user_id = current_user.id if logged_in?
    comment.category_code = 3
    commentable.add_comment comment
    # reload the comment so we can get the id
    comment.reload
    
    
    render :update do |page|  
      page.insert_html :bottom, "reports#{ commentable.id }", :partial => "/comments/comment_and_reply", :locals => { :comment => comment }  
      page.visual_effect :highlight, "comment#{ comment.id }"  
    end
  end
    
  protected  
    
  # Gets the rateable class based on the params[:rateable_type]  
  def get_class_by_name  
    bad_class = false  
    begin  
      @rateable_class = Module.const_get(params[:rateable_type])  
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
  end  
  
end