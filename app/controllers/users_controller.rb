require 'open-uri'
require 'hpricot'

class UsersController < ApplicationController  
  
  ssl_required :new, :create
  
  before_filter :login_required, :except => [:show, :new, :create, :index, :show_memberships, :show_support, :show_comments, :show_page, :show_articles, :show_notifications, :show_blog]
  
  def index
    if params[:all]
      @users = User.all(:include => :districts)
    else
      @users = User.authenticated_users.all(:include => :districts, :order => 'created_at DESC')#.paginate(:page => params[:page], :per_page => 13)
    end
    render :template => 'users/list'
  end
  
  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.login = @user.email
    @user.zip = ""
    @user.facebook_id = nil
    if @user.save
      #todo generate a notification to the community and district

      # welcome the user via a notification.
      @user.notifications << Notification.new(:message => "Welcome to Democracy Universal.", :from_user_id => 1)

      flash[:notice] = "<p>Aloha and welcome to Democracy Universal.</p><p>Get started by choosing an Available Democracy</p>"
      self.current_user = @user
      redirect_back_or_default "/" #suggest_districts_path
    else
      render :action => 'new'
    end
  end
  
  def show
    if params[:id]
      @user = User.find(params[:id])
      if params[:p]
        @page = @user.pages.find(params[:p])
      else
        @page = @user.pages.first
        if @page.nil?
          @page = Page.create
          @user.pages << @page
        end
      end
    else
      flash[:error] = "<p>nobody to see here. step away</p>"
      redirect_to :back
    end
  end
  
  def update
    current_user.update_attribute('profile_pic', params[:user][:profile_pic])
    redirect_to user_path current_user
  end
  
  def hide_notification
    note = Notification.find(params[:id])
    # todo consider whether this should be done with permissions or not
    # consider whether to check the permissions in the model or the controller. probably the model. move this in there?
    if logged_in? && note.user_id == @current_user.id
      note.hide!
    end
    redirect_to :back
  end
  
  def new_notification
    @notification = Notification.new(params[:notification])
    @notification.from_user = current_user if logged_in?
    @user = User.find(params[:id])
    if @user.notifications << @notification
      render :update do |page|  
        page.replace_html "new_notification", "<p id='jesus'>Message has been sent</p>"
        page.visual_effect :highlight, "jesus"  
      end
    else
      render :update do |page|  
        page.insert_html :top, "new_notification", "<p id='jesus'>Message failed to send</p>"
        page.visual_effect :highlight, "jesus"  
      end
    end
  end
  
  def new_blog
    user = current_user
    blog = Comment.create(params[:comment])
    # essential to override the comment to be a blog. ie 4
    blog.category_code = 4
    if user.comments << blog
      render :update do |page|  
        page.replace_html "new_blog", "<p id='jesus'>Post successful</p>"
        page.visual_effect :highlight, "jesus"
        page.insert_html :top, "new_blog_entry", :partial => 'blog_entry', :locals => { :blog_entry => blog }
      end
    else
      render :update do |page|  
        page.insert_html :top, "new_blog", "<p id='jesus' class='error'>Faied to Post</p>"
        page.visual_effect :highlight, "jesus"  
      end
    end
  end
  
  def show_disclosure
    @user = User.find(params[:id])
    render(:partial => 'users/disclosure')
  end
  def show_memberships
    @user = User.find(params[:id])
    render :partial => 'memberships'
  end  
  def show_support
    @user = User.find(params[:id])
    render :partial => 'support'
  end
  def show_comments
    render :partial => '/comments/show', :locals => { :comments => Comment.find_comments_by_user(User.find(params[:id])) }
  end
  def show_page
    render :text => textile(Page.find(params[:id]).content)
  end
  def show_articles
    @user = User.find(params[:id])
    render :partial => 'authored'
  end
  def show_notifications
    @user = User.find(params[:id])
    render :partial => 'show_notifications'
  end
  def show_blog
    @user = User.find(params[:id])
    render :partial => 'message'
  end
  def show_manage
    @user = User.find(params[:id])
    render :partial => 'manage'
  end
  
  def update_login
    if logged_in? && current_user.has_privilege?('edit users')
      user = User.find(params[:id])
      user.update_attribute('login', params[:value])
      user.reload
      render :text => user.login
    else
      flash[:error] = "<p>Massive Failure</p>"
      redirect_to '/'
    end
  end
  
  def update_name
    user = User.find(params[:id])
    if logged_in? && current_user == user
      user.update_attribute('name', params[:value])
      user.reload
      render :text => user.name
    else
      flash[:error] = "<p>Massive Failure</p>"
      redirect_to user
    end
  end
  
  def get_disclosure
    page = Page.find(params[:id])
    if page.blank?
      render :text => "Create your disclosure here"
    else
      render :text => page.content
    end
  end
  def update_disclosure
    page = Page.find(params[:id])
    page.content = params[:value]
    page.save
    page.reload
    render :text => textile(page.content)
  end

end
