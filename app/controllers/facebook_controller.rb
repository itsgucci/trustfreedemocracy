require 'ruby-debug'

class FacebookController < ApplicationController
  
  before_filter :require_facebook_login
  
  def index    
    #debugger
    unless logged_in?
      if user= User.find_by_facebook_id(facebook_user)
        self.current_user = user
      end
    end
    unless logged_in? 
      new_user = User.new
      new_user.facebook_id = facebook_user
      # todo: purge this nasty
      new_user.save_without_validation
      self.current_user = new_user.reload
    end
    flash[:notice] = "<p>Aloha, <fb:name uid='loggedinuser' useyou='false'></fb:name></p>"
    redirect_to '/'
  end
  
  def profile
    render :layout => false
  end
  
end
