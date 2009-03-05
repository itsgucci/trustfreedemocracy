class CommunitiesController < ApplicationController  
  
  before_filter :login_required, :except => [:index, :show, :agenda, :show_actions, :show_info, :show_members, :show_reps, :show_calendar, :show_minutes, :show_charter, :show_budget, :show_laws, :show_changes]
  
  def index
    @communities = Community.all
  end
  
  def new
    @community = Community.new
  end
  
  def create
    @community = Community.new(params[:community])
    Community.transaction do
      @community.save
      @community.chairperson = current_user
    end
    redirect_to @community
  end
  
  def show
    @community = Community.find(params[:id])
    self.current_community = @community
    self.current_district = nil unless @community.districts.include? current_district
    @actions = Community.find(params[:id]).actions.paginate(:page => params[:page], :per_page => 13)
  end
  
  def agenda
    @community = Community.find(params[:id])
  end
  
  def certify
    @community = current_community
  end
  
  def manage_community
    @community = Community.find(params[:id])
  end
  
  def manage_certification
    @community = Community.find(params[:id])
    unless current_user.has_privilege?('certify users', @community)
      flash[:error] = "<p>Not for you</p>"
      redirect_to @community
      return false
    end
  end
  def generate_certifications
    community = Community.find(params[:id])
    if current_user.has_privilege?('certify users', community)
      name = params[:name]
      district = District.find(params[:district])
      Certification.generate_certificate(district.id, name, "TrustFreeDemocracy", nil)
      flash[:notice] = "<p>Certification Added</p>"
    else
      flash[:error] = "<p>Not for you</p>"
    end
    redirect_to :back
  end
  
  def toggle_clerk
    @community = Community.find(params[:id])
    if current_user.has_privilege?('manage community', @community)
      clerk = User.find_by_login(params[:clerk])
      if @community.clerks.include? clerk
        @community.remove_clerk clerk
        action = "removed"
      else
        @community.add_clerk clerk
        action = "added"
      end
    end
    flash[:notice] = "<p>#{ clerk.name } has been #{ action } as a Clerk</p>"
    redirect_to @community
  end
  
  def adjust_budget
    @community = Community.find(params[:id])
    if current_user.has_privilege?('manage community', @community)
      if @community.adjust_budget(params[:value], current_user)
        render :update do |page|
          page.replace_html 'current_budget', @community.assets
          page['adjust_budget_form'].reset
        end
      else
        render :text => "Change Failed"
      end
    end
  end
  
  def update_name
    @community = Community.find(params[:id])
    if current_user.has_privilege?('manage community', @community)
      if @community.update_attribute(:name, params[:value])
        render :text => @community.name
      else
        render :text => "Change Failed"
      end
    end
  end
  def update_chairperson
    if current_user.has_privilege?('manage communities')
      @community = Community.find(params[:id])
      user = User.find(params[:value])
      if @community.chairperson = user
        @community.chairperson.reload
        render :text => @community.chairperson.name
      end
    else
      render :text => "Change Failed"
    end
  end
  def update_tax_population
    if current_user.has_privilege?('manage communities')
      @community = Community.find(params[:id])
      @community.update_attribute(:tax_population, params[:value])
      @community.reload
      render :text => @community.tax_population
    else
      render :text => "error"
    end
  end
  
  def visibility_toggle
    if current_user.has_privilege?('manage communities')
      @community = Community.find(params[:id])
      @community.toggle('visible')
      @community.save
      render :text => "great success"
    end
  end
  
  def get_calendar
    community = Community.find(params[:id])
    page = community.calendar_page
    if page.content.blank?
      render :text => "Create your treasurers report here"
    else
      render :text => page.content
    end
  end
  def update_calendar
    community = Community.find(params[:id])
    if current_user.has_privilege?('manage community', community)
      page = community.calendar_page
      page.content = params[:value]
      page.save
      page.reload
      render :text => textile(page.content)
    else
      render :text => "you are not authorized"
    end
  end
  
  def create_minutes
    community = Community.find(params[:id])
    if current_user.has_privilege?('edit minutes', community)
      comment = Comment.new(params[:comment])
      comment.user = current_user
      comment.category_code = 5
      if community.comments << comment
        render :update do |page|
          comment.reload
          page.insert_html :top, "create_minutes_return", :partial=>"minute", :object=> comment
          page.visual_effect 'slide_down', "minute#{comment.id}"
          page['minutes_form'].reset
          page['comment_comment'].rows = 5
          page['comment_comment'].value = "Minutes recorded sucessfully!"
        end
      else
        render :update do |page|
          page.insert_html :top, "create_minutes_return", "<p class='error'>Minutes were not Recorded</p>"
        end
      end
    end
  end
  def update_minutes
    comment = Comment.find(params[:id])
    if current_user.has_privilege?('edit minutes', comment.commentable)
      comment.comment = params[:value]
      comment.save
      comment.reload
      render :text => textile(comment.comment)
    end
  end
  def get_minutes    
    comment = Comment.find(params[:id])
    render :text => comment.comment
  end
  
  def get_disclosure
    
  end
  def update_disclosure
    page = Page.find(params[:id])
    if current_user.has_privilege?('manage community', page.pageable)
      page.content = params[:value]
      page.save
      page.reload
      render :text => textile(page.content)
    end
  end
  
  def update_charter
    community = Community.find(params[:id])
    page = community.charter_page
    if current_user.has_privilege?('manage community', community)
      page.content = params[:page][:content]
      page.save
      page.reload
      render :text => textile(page.content)
    end
  end
  
  def show_actions
    actions = Community.find(params[:id]).actions.paginate(:page => params[:page], :per_page => 13)
    render :partial => 'shared/action_paginated', :locals => { :actions => actions }
  end
  def show_changes
    @community = Community.find(params[:id])
    render :partial => 'changes'
  end
  def show_laws
    @community = Community.find(params[:id])
    @laws_grid = initialize_grid(Article, :conditions => ['community_id = ? AND session = ?', @community.id, @community.current_session], :per_page => 26, :include => [:community, :district])
    render :partial => 'laws'
  end
  def show_info
    @community = Community.find(params[:id])
    render :partial => 'info'
  end
  def show_members
    @district = if current_district.nil?
      Community.find(params[:id])
    else
      current_district
    end
    render :partial => 'districts/members'
  end
  def show_reps
    @community = Community.find(params[:id], :include => :representatives)
    render :partial => 'representatives'
  end
  def show_budget
    @community = Community.find(params[:id])
    render :partial => 'budget'
  end
  def show_minutes
    @community = Community.find(params[:id])
    render :partial => 'minutes'
  end
  def show_charter
    @community = Community.find(params[:id])
    @community.charter_page
    render :partial => 'charter'
  end
  
end
