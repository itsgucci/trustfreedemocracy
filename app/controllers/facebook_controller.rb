require 'ruby-debug'

class FacebookController < ApplicationController
  
  ensure_authenticated_to_facebook
  #ensure_application_is_installed_by_facebook_user
  
  def index
    session[:facebook_session].secure_from_connect!
    #debugger
    unless logged_in?
      if user= User.find_by_facebook_id(facebook_user.id)
        self.current_user = user
      end
    end
    unless logged_in? 
      new_user = User.new
      new_user.facebook_id = facebook_user.id
      # todo: purge this nasty
      new_user.save_without_validation
      self.current_user = new_user.reload
    end
    flash[:notice] = "<p>Aloha, <fb:name uid='loggedinuser'></fb:name></p>"
    redirect_to '/'
  end
  
  def profile
    render :layout => false
  end
  
end
