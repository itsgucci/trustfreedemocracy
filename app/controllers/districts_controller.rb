require 'open-uri'
require 'hpricot'
require 'ruby-debug'

class DistrictsController < ApplicationController
  
  before_filter :login_required, :except => [:show, :new, :agenda, :show_actions, :show_members, :show_comments, :show_focus, :show_support, :show_articles, :show_info, :show_representative, :show_rep_blog, :change_district]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :show }
  
  def change_district
    if params[:id] == "0"
      self.current_district = nil
    else
      self.current_district = District.find(params[:id])
    end
    redirect_to :back
  end
  
  def show
    if params[:id] == "0"
      self.current_district = nil
      redirect_to self.current_community
    else
      @district = District.find(params[:id])
      self.current_district = @district
      self.current_community = @district.community
    end
  end
  
  def agenda
    if params[:id]
      self.current_district = District.find(params[:id])
    end
    @list = current_district.articles.if_certified(certification_filter?).focuses.all(:order => 'focus_count DESC, support_count DESC')
  end

  def new
    @district = District.new
  end

  def create
    @district = District.new(params[:district])
    if @district.save
      flash[:notice] = 'District was successfully created.'
      render :update do |page|
        page.insert_html :bottom, :district_list, "<li>#{ link_to_remote @district.name, :url => {:controller => 'districts', :action => 'manage_district', :id => @district}  }</li>"
      end
    else
      render :action => 'new'
    end
  end
  
  def add_tag
    if request.xhr?
      district = District.find(params[:id])
      if district.tags.include?(params[:tag])
        district.tags.remove(params[:tag])
        render :update do |page|
          page.remove 'tag' + tag.id.to_s
        end
      else
        district.tag_with(params[:tag])
        tag = Tag.find_by_name(params[:tag])
        render :update do |page|
          page.insert_html :bottom, 'tags', :partial => 'shared/tag', :object => tag
        end
      end
    end
  end
  
  def certify
    @district = District.find(params[:id])
  end
  
  def manage_district
    if request.xhr?
      @district = District.find(params[:id]) rescue nil
      if @district
        # the code below will render all your RJS code inline and
        # u need not to have any .rjs file, isnt this interesting
        render :update do |page|
          page.hide "district_management"
          page.replace_html "district_management", :partial=>"district_edit"
          page.visual_effect 'toggle_appear', "district_management"
        end
      else
        render :nothing => true
      end
    end
  end
  
  def update_name
    @district = District.find(params[:id])
    @district.update_attribute :name, params[:value]
    @district.reload
    render :text => @district.name
  end
  
  def update_representative
    @district = District.find(params[:id])
    user = params[:value].blank? ? nil : User.find(params[:value])
    if @district.representative = user
      render :text => @district.representative.name
    else
      render :text => "Change Failed"
    end
  end
  def update_description
    district = District.find(params[:id])
    district.description = params[:value]
    if district.save
      render :text => district.description
    else
      render :text => "Change Failed"
    end
  end
  
  def move_top_priority_into_session
    @district = District.find(params[:id])
    top_priority = @district.top_priority
    top_priority.move_to_comite
    redirect_to article_path( top_priority )
  end
  
  def suggest
    # this is messy and should be taken out of the user controller
    zip = params[:name]
      @districts = []; state = ""
      response = Hpricot(open("http://services.sunlightlabs.com/api/districts.getDistrictsFromZip.xml?apikey=e0a7a09436fa8c75c7efff35519e9067&zip=#{ zip }"))
      (response/:district).each do |district|
        state = state_abbr((district/:state).html)
        @districts << District.find( :all, :conditions => ["name LIKE ?", state + ' ' + (district/:number).html + '%'])
      end

      if false && state.upcase == "HAWAII"
        response = Hpricot(open("http://elections2.hawaii.gov/ppl/PPL_PS_10_010_1.ASPX"))
        validation = (response/"#__EVENTVALIDATION").first[:value]
        view = (response/"#__VIEWSTATE").first[:value]
        res = Net::HTTP.post_form(URI.parse('http://elections2.hawaii.gov/ppl/PPL_PS_10_010_1.ASPX'), {'txtFirstName' => @user.first_name, 'txtLastName' => @user.last_name, 'txtDOB' => '7/26/85', "__EVENTVALIDATION" => validation, '__VIEWSTATE' => view, 'btnSearch' => "Search"})
        doc = Hpricot(res.body)
        doc = Hpricot(open("http://elections2.hawaii.gov" + (doc/"a").first[:href]))
        @county = (doc/"#LabelCouncil").html
      end

      @districts.flatten!

      @districts -= current_user.districts if logged_in?  
  end
  
  def join
    @district = District.find(params[:id])
    certificate = params[:certificate]
    keycode = params[:keycode]
    if @district.register current_user, certificate, keycode
      flash[:notice] = "<p>You have become a Member of #{ @district.name }</p><p>Welcome aboard</p>"
      redirect_back_or_default district_path(@district)
    else
      flash[:error] = "<p>Joining #{ @district.name } failed</p>"
      render :action => 'certify'
    end
  end
  def leave
    @district = District.find(params[:id])
    if @district.leave current_user
      flash[:notice] = "<p>You have seceded from #{ @district.name }</p>"
    else
      flash[:error] = "<p>Secession failed</p>"
    end
    redirect_to district_path(@district)
  end
  
  def certify_user
    @district = District.find(params[:id])
    if current_user.has_privilege?('certify users', @district.community)
      user = User.find(params[:user])
      if @district.certify user
        flash[:notice] = "#{ user.name } now certified in #{ @district.name }"
      else
        flash[:error] = "Failed to certify #{ user.name } in #{ @district.name}"
      end
    else
      flash[:error] = "You can not certify users."
    end
    redirect_to :back
  end
  
  def show_actions
    @district = District.find(params[:id])
    render(:partial => '/shared/action', :locals => { :actions => @district.actions.paginate(:page => params[:page], :per_page => 13) })
  end
  def show_members
    @district = District.find(params[:id])
    render :partial => 'districts/members'
  end
  def show_comments
    @district = District.find(params[:id])
    render :partial => '/comments/show', :locals => { :comments => @district.comments.sort_by { |c| c.created_at }.reverse }
  end
  def show_focus
    @district = District.find(params[:id])
    render :partial => 'districts/focus'
  end
  def show_support
    @district = District.find(params[:id])
    render :partial => 'districts/support'
  end
  def show_articles
    @district = District.find(params[:id])
    render :partial => 'districts/articles'
  end
  def show_info
    @district = District.find(params[:id])
    render :partial => 'districts/info'
  end
  def show_representative
    @district = District.find(params[:id])
    render :partial => 'representative'
  end
  def show_rep_blog
    # full gangster on this one
    @user = District.find(params[:id])
    render :partial => '/users/show_blog'
  end

end
