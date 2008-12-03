# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  
  ssl_required :new, :create, :login_iframe
  
  # render new.rhtml
  def new
    session[:return_to] = request.env['HTTP_REFERER'] unless session[:return_to]
    render :template => '/sessions/login'
  end

  def create
    # if they don't supply parameters, try to populate from facebook
    unless self.current_user = User.authenticate(params[:login], params[:password])
      self.current_user = User.find_by_facebook_id(facebook_user.id) if facebook_user
    end
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      respond_to do |format|
        format.html do |html|
          flash[:notice] = "<p>Aloha, #{ self.current_user.name }</p>"
          redirect_back_or_default :back
        end
        format.js { render :text => "accountability established" }
      end
    else
      flash[:error] = "<p>Login Unsuccessful</p>"
      render :template => '/sessions/login'
    end
  end
  
  def impersonate_user
    # we only want the admin to do this. okay.
    if logged_in? && current_user.has_privilege?('impersonate users')
      self.current_user = User.find(params[:id])
      flash[:notice] = "<p>You are now #{ current_user.name }. With great power comes great responsibility</p>"
    else
      flash[:error] = "<p>No way</p>"
    end
    redirect_to '/'
  end
  
  def set_district
    self.current_district = District.find(params[:id])
    self.current_community = self.current_district.community
    redirect_to :back
  end
  
  def home
    # not sure if we really want this, but clear the current district and community?
    unless current_community
      self.current_community = Community.find 1
    end
  end
  
  def add_tag_to_sieve
    @tag = Tag.find(params[:id])
    sieve.add(@tag)
  end
  def remove_tag_from_sieve
    @tag = Tag.find(params[:id])
    sieve.remove(@tag)
  end
  
  def mail_signup
    @mail = MailingList.new(params[:mail])
    @mail.active = true
    if @mail.save
      render :text => "You have signed up!"
    elsif MailingList.exists?(:email => @mail.email)
      render :text => "That email address is already signed up!"
    else
      render :text => "Signing up failed"
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "<p>You have been logged out</p>"
    # they are logging out, they should go to a fresh home.
    redirect_to '/'
  end
  
  def cert_toggle
    toggle_certification_filter
    
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do |page|
        render :text => certification_filter? ? "certified" : "uncertified"
      end
    end
  end
  
  def login_iframe
    render :layout => 'only_stylesheet'
  end
  
  def options
    
  end
  
  
end
