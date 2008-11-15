class Admin::NotificationsController < ApplicationController
  # GET /admin_notifications
  # GET /admin_notifications.xml
  def index
    respond_to do |format|
      format.html { redirect_to :action => 'new' }
      format.xml  { render :xml => @admin_notifications }
    end
  end

  # GET /admin_notifications/new
  # GET /admin_notifications/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notifications }
    end
  end

  # POST /admin_notifications
  # POST /admin_notifications.xml
  def create
    @users = User.find(:all)
    @users.each { |user| user.notifications << Notification.new(params[:notification]) }

    respond_to do |format|
        flash[:notice] = 'Notifications were successfully sent.'
        format.html { redirect_to( :action => 'new' ) }
        format.xml  { render :xml => @notifications, :status => :created, :location => @notifications }
    end
  end
end
