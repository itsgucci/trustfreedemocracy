class FacebookController < ApplicationController
  
  ensure_authenticated_to_facebook
  
  def index
    #login via facebook
    unless logged_in?
      if self.current_user = User.find_by_facebook_id(facebook_user.id)
        flash[:notice] = "<p>Aloha, #{current_user.name}</p>"
        redirect_to '/'
        return false
      end
    end
    @user = facebook_user
  end
  
  def associate
    if logged_in? && facebook_user
      self.current_user.facebook_id = facebook_user.id
      self.current_user.save
      flash[:notice] = "<p>#{current_user.name} linked with Facebook id: #{facebook_user.id}</p>"
      redirect_to '/facebook'
      return true
    end
    flash[:error] = "<p>Association failed</p>"
    redirect_to :back
  end
  def disassociate
    current_user.update_attribute('facebook_id', nil)
    flash[:notice] = "<p>No longer linked to Facebook</p>"
    redirect_to :back
  end
  
  def article
    @article = Article.find(params[:id])
    render :template => 'articles/show'
  end
  
  def show
    @fb_user = session[:facebook_session].user
    @user = User.find_by_facebook_id(@fb_user.id)
  end
  
end
