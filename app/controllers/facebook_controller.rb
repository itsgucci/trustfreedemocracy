require 'ruby-debug'

class FacebookController < ApplicationController
  
  before_filter :require_facebook_login
  
  def index
    # debugger
    # if cookies["#{FACEBOOK['key']}_session_key"]
    #   fbsession.activate_with_previous_session(cookies["#{FACEBOOK['key']}_session_key"])
    # end
    #debugger
    fbsession.auth_promoteSession
    if user= User.find_by_facebook_id(facebook_user)
      self.current_user = user
    else
      new_user = User.new
      new_user.facebook_id = facebook_user
      # todo: purge this nasty
      new_user.save_without_validation
      self.current_user = new_user.reload
    end
    flash[:notice] = "<p>Aloha, <fb:name uid='loggedinuser' useyou='false' linked='false'></fb:name>. Welcome to Democracy Universal</p>"
    redirect_to '/'
  end
  
  def profile
    render :layout => false
  end
  
end
