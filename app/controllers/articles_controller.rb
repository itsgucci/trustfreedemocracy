require 'ruby-debug'

class ArticlesController < ApplicationController  
  
  before_filter :login_required, :except => [:index, :new, :show, :show_action, :show_support, :show_discussion, :show_focus, :show_reports, :show_results, :show_vote, :show_management]
  #before_filter :login_required, :only => [:create, :destroy, :endorse, :unendorse, :add_support, :remove_support, :move_into_session, :vote]
  #before_filter :district_membership_required, :only => [:new, :create, :endorse, :unendorse]
  #before_filter :community_membership_required, :only => [:add_support, :remove_support, :vote]
  
  def index
    if current_district || current_community
      community = current_community || current_district.community
      @articles = community.articles.search params[:search], :page => params[:page], :per_page => 13, :order => "support_count DESC"
    else
      @articles = Article.search params[:search], :page => params[:page], :per_page => 13, :order => "support_count ASC"
    end
    
    @search_terms = params[:search]
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @articles }
    end
  end
  
  def new
    if params[:district]
      self.current_district = District.find params[:district]
      self.current_community = current_district.community
    end
    @article = Article.new(:district => current_district)
  end
  
  def create
    if request.post?
      
      # short circut them if it already exists and return them this
      if params[:article][:tom_id]
        if article = Article.find_by_tom_id(params[:article][:tom_id])
          redirect_to article
          return false
        end
      end
      # otherwise assume it is a new article
      # create the article
      article = Article.new(params[:article])
      # enforce server side variables
      article.community = current_community
      article.article_type_id = params[:type]
      article.cost = "0" if article.cost.nil?
      #certify the article
      if article.district
        article.certified = article.district.certified? current_user
      else
        article.certified = false
      end
      if article.save
        if logged_in? && has_privilege?('set author') && params[:user_id]
          article.author = User.find(params[:user_id])
        else
          article.author = current_user
        end    
          article.actions.create(:house => "O", :action => "New #{ article.article_type.name }: #{ article.title }", :district_id => article.district.id, :processed => true )
        flash[:notice] = "<p>This #{ article.article_type.name } is now in the Develop Legislation stage of #{ article.district.name }</p><p>You are the author and may edit this Motion as you see fit</p><p>Share link: #{ article_url(article) }</p>"
        redirect_to article
      else
        render :action => 'new'
      end
    else
      render :action => 'new'
    end
  end
  
  def show
    @article = Article.find(params[:id])
    # set the currents for this article. helps when coming in from an external link
    self.current_district = @article.district if @article.district
    self.current_community = @article.community
  end
  
  def destroy
    @article = Article.find(params[:id])
    if current_user.has_privilege?('kill article', @article) || current_user.has_privilege?('kill article', @article.community)
      if @article.kill
        flash[:notice] = "<p>Motion has been killed</p>"
      else
        flash[:error] = "<p>Motion could not be killed</p>"
      end
    else
      flash[:error] = "<p>You can not kill this Motion</p>"
    end
    redirect_to @article
  end
  
  def endorse
    @article = Article.find(params[:id])
    # have to cancel previous endorsement
    if logged_in? && @article.endorse(current_user)
      render :update do |page|
        page.replace_html 'endorsement_area', :partial => 'articles/withdraw_focus'
        page.insert_html :bottom, "user_focus_list#{ @article.id }", "<li id='user_focuser#{ @article.id.to_s + '_' + current_user.id.to_s }'>#{ link_to current_user.name, current_user }</li>"     
        page.visual_effect :highlight, "user_focuser#{ @article.id.to_s + '_' + current_user.id.to_s }", :start_color => '"#ff6600"', :end_color => '"#ffffff"'
        page.replace_html "focus_image#{ @article.id }", :partial => 'articles/focus_image'
        page.replace_html "focus_summary#{ @article.id }", :partial => 'articles/focus_summary'
      end
    else
      render :text => "error"
    end
  end
  def unendorse
    @article = Article.find(params[:id])
    if @article.unendorse(current_user)
      render :update do |page|
        page.replace_html 'endorsement_area', :partial => 'articles/add_focus'
        page.visual_effect :fade, "user_focuser#{ @article.id.to_s + '_' + current_user.id.to_s }"
        page.remove "user_focuser#{ @article.id.to_s + '_' + current_user.id.to_s }"
        page.replace_html "focus_image#{ @article.id }", :partial => 'articles/focus_image'
        page.replace_html "focus_summary#{ @article.id }", :partial => 'articles/focus_summary'
      end
    end
  end
  
  def add_support
    @article = Article.find( params[:id] )
    if @article.add_support(current_user)
      render :update do |page|
        page.replace_html "support_area#{ @article.id }", :partial => 'articles/withdraw_support', :locals => { :object => @article }
        page.insert_html :bottom, "user_supporter_list#{ @article.id }", "<li id='user_supporter#{ @article.id.to_s + '_' + current_user.id.to_s }'>#{ link_to current_user.name, { :controller => 'users', :action => 'show', :id => current_user.id } }</li>"     
        page.visual_effect :highlight, "user_supporter#{ @article.id.to_s + '_' + current_user.id.to_s }", :start_color => '"#ff6600"', :end_color => '"#ffffff"'
        page.replace_html "support_image#{ @article.id }", :partial => 'articles/support_image'
        #page.call 'function Reflection.add' "($('support_image#{ @article.id }'))"
        page.replace_html "support_summary#{ @article.id }", :partial => 'articles/support_summary'
      end
    # this else is because if the user already supports the bill, and then they log in it will reflect that they do instead of just returning a 'new' form
    else
      render :update do |page|
        if @article.supported_by?(current_user)
          page.replace_html "support_area#{ @article.id }", :partial => 'articles/withdraw_support', :locals => { :object => @article }
        else
          page.replace_html "support_area#{ @article.id }", :partial => 'articles/add_support', :locals => { :object => @article }
        end
      end
    end
  end
  
  def remove_support
    @article = Article.find(params[:id])
    if @article.withdraw_support(current_user)
      render :update do |page|
        page.replace_html "support_area#{ @article.id }", :partial => 'articles/add_support', :locals => { :object => @article }
        page.visual_effect :fade, "user_supporter#{ @article.id.to_s + '_' + current_user.id.to_s }"
        page.remove "user_supporter#{ @article.id.to_s + '_' + current_user.id.to_s }"
        page.replace_html "support_image#{ @article.id }", :partial => 'articles/support_image'
        page.replace_html "support_summary#{ @article.id }", :partial => 'articles/support_summary'
      end
    end
  end
  
  def vote
    @article = Article.find( params[:id] )
    
    vote = Vote.first(:conditions => { :user_id => current_user, :voteable_id => @article.id, :voteable_type => 'Article' } ) || Vote.new(:user => current_user )
    vote.vote = case params[:vote]
    when "aye"
      1
    when "nay"
      0
    when "present"
      2
    when "novote"
      nil
    end
    
    if @article.votes << vote
      render :update do |page|
        page.replace_html 'vote_return', :partial => 'receipt', :locals => {:vote => vote}
        page.visual_effect 'slide_down', :vote_return
        page.replace_html 'tally_container', :partial => 'tally'
        #page.visual_effect 'highlight', :tally_container, :start_color => '"#ff6600"', :duration => 3
      end
    else
      render :update do |page|
        page.replace_html 'vote_return', "<p class='error'>Ballot was not cast</p>"
      end
    end
  end
  
  privilege_required 'set author', :only => :update_author
  def update_author
    @article = Article.find(params[:id])
    @article.author = User.find(params[:value])
    @article.reload
    render :text => @article.author.name
  end
  
  privilege_required 'finalize article', :on => Article, :param => :id, :only => :finalize
  def finalize
    article = Article.find( params[:id] )
    if article.finalize_draft
      message = "<a href='/articles/#{ article.id }'>#{ article.number } - #{ article.title }</a>, which you support has been finalized."
      article.notify_supporters(message)
    end
    flash[:notice] = "Your Draft has been finalized! The community may now decide if this is their Top Priority."
    redirect_to article_path(article)
  end
  
  def move_into_session
    @article = Article.find(params[:id])
    if current_user.has_privilege?('move into session', @article.district)
      @article.move_to_comite
      flash[:notice] = "This Motion has been opened for formal discussion"
    else
      flash[:error] = "You may not open Motions for discussion!"
    end
    redirect_to article_path(@article)
  end
  
  def move_to_vote
    @article = Article.find(params[:id])
    if current_user.has_privilege?('move to vote', @article.community)
      @article.move_to_vote
      flash[:notice] = "This Motion is now open for voting"
    else
      flash[:error] = "You may not open this Motion for vote!"
    end
    redirect_to article_path(@article)
  end
  
  privilege_required 'edit article', :on => Article, :param => :id, :only => [:update_title, :update_budget, :update_idea, :update_proposal]
  def update_title
    @article = Article.find(params[:id])
    @article.update_attribute "title", params[:value]
    @article.reload
    render :text => @article.title
  end
  def update_budget
    article = Article.find(params[:id])
    article.update_budget params[:value]
    render :text => Object.new.extend(ActionView::Helpers::NumberHelper).number_to_currency(article.cost || 0)
  end
  def get_budget
    article = Article.find(params[:id])
    render :text => Object.new.extend(ActionView::Helpers::NumberHelper).number_to_currency(article.cost)
  end
  def update_idea
    idea = Article.find(params[:id])
    idea.summary = params[:value]
    idea.save
    idea.reload
    render :text => textile(idea.summary)
  end
  def get_idea
    idea = Article.find(params[:id])
    render :text => idea.summary
  end
  def update_proposal
    idea = Article.find(params[:id])
    idea.text = params[:value]
    idea.save
    idea.reload
    render :text => textile(idea.text)
  end
  def get_proposal
    idea = Article.find(params[:id])
    render :text => idea.text
  end
  
  def show_action
    @article = Article.find(params[:id])
    render :partial => 'action'
  end
  def show_support
    @article = Article.find(params[:id])
    render :partial => '/shared/support'
  end
  def show_discussion
    article = Article.find(params[:id])
    category = 0
    # sort the comments by rating
    comments = article.discussion.sort { |a,b| b.rating <=> a.rating }
    render :partial => '/comments/thread', :locals => { :comments => comments, :thread_id => article.id, :category => category }
  end
  def show_focus
    @article = Article.find(params[:id])
    render :partial => '/shared/focus'
  end
  def show_reports
    @article = Article.find(params[:id])
    render :partial => '/comites/report'
  end
  def show_results
    @article = Article.find(params[:id])
    render :partial => 'results'
  end
  def show_vote
    @article = Article.find(params[:id])
    render :partial => 'vote'
  end
  def show_management
    @article = Article.find(params[:id])
    render :partial => 'manage'
  end
  
end