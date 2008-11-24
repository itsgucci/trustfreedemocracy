# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_heed_session_id'
  
  include SslRequirement  
  include AuthenticatedSystem
  
  def district_membership_required
    unless current_district
      flash[:error] = "Fatal Error: No government selected"
      redirect_to '/'
      return false
    end
    unless current_district.member? current_user
      store_location
      flash[:error] = "You must be a member of #{ current_district.full_name } to continue with this action"
      redirect_to certify_district_path(current_district)
    end
  end
  def community_membership_required
     unless current_community
       flash[:error] = "Fatal Error: No government selected"
       redirect_to '/'
       return false
     end
     unless current_community.member? current_user
       store_location
       flash[:error] = "You must be a member of #{ current_community.name } to continue with this action"
       redirect_to certify_community_path(current_community)
     end
   end
	
	def help_toggle
	  if session[:help].nil?
	    session[:help] = false
    else
  	  session[:help] = !session[:help]
	  end
	  redirect_to :back
  end
  
  def add_tag
    if request.xhr?
      article = Article.find(params[:id])
      article.tag_with(params[:tag], params[:interest_id], current_user)
      render :update do |page|
        page.replace_html 'module_area', :partial => 'modules/describe/describe', :object => @object
      end
    end
  end
  
  helper_method :current_district
  # Accesses the current user from the session.  Set it to :false if login fails
   # so that future calls do not hit the database.
  def current_district
    @current_district ||= (district_login_from_session || nil)
  end
  # Store the given user in the session.
  def current_district=(new_district)
    session[:district] = (new_district.nil? || new_district.is_a?(Symbol)) ? nil : new_district.id
    @current_district = new_district
  end
  def district_login_from_session
    self.current_district = District.find(session[:district]) if session[:district]
  end
  
  helper_method :current_community
  def current_community
    @current_community ||= (community_login_from_session || Community.first)
  end
  def current_community=(new_community)
    session[:community] = (new_community.nil? || new_community.is_a?(Symbol)) ? nil : new_community.id
    @current_community = new_community
  end
  def community_login_from_session
    self.current_community = Community.find(session[:community]) if session[:community]
  end
  
  helper_method :facebook_user
  def facebook_user
    return nil unless session[:facebook_session] && !session[:facebook_session].expired?
    session[:facebook_session].user
  end
         
  helper_method :current_zip
  def current_zip
    session[:current_zip]
  end
  
  helper_method :sieve
  def sieve
    @sieve ||= Sieve.new(session)
  end
  
  helper_method :certification_filter?
  def certification_filter?
    session[:certification_filter] || false
  end
  def toggle_certification_filter
    session[:certification_filter] ||= false
    session[:certification_filter] = !session[:certification_filter]
  end
  
  
  helper_method :textile
  def textile(text)
     if text.blank?
       ""
     else
       RedCloth.new(text).to_html
     end
   end
	def state_abbr(abbr)
	  @state_abbr ||= {
     'AL' => 'Alabama',
     'AK' => 'Alaska',
     'AS' => 'America Samoa',
     'AZ' => 'Arizona',
     'AR' => 'Arkansas',
     'CA' => 'California',
     'CO' => 'Colorado',
     'CT' => 'Connecticut',
     'DE' => 'Delaware',
     'DC' => 'District of Columbia',
     'FM' => 'Micronesia1',
     'FL' => 'Florida',
     'GA' => 'Georgia',
     'GU' => 'Guam',
     'HI' => 'Hawaii',
     'ID' => 'Idaho',
     'IL' => 'Illinois',
     'IN' => 'Indiana',
     'IA' => 'Iowa',
     'KS' => 'Kansas',
     'KY' => 'Kentucky',
     'LA' => 'Louisiana',
     'ME' => 'Maine',
     'MH' => 'Islands1',
     'MD' => 'Maryland',
     'MA' => 'Massachusetts',
     'MI' => 'Michigan',
     'MN' => 'Minnesota',
     'MS' => 'Mississippi',
     'MO' => 'Missouri',
     'MT' => 'Montana',
     'NE' => 'Nebraska',
     'NV' => 'Nevada',
     'NH' => 'New Hampshire',
     'NJ' => 'New Jersey',
     'NM' => 'New Mexico',
     'NY' => 'New York',
     'NC' => 'North Carolina',
     'ND' => 'North Dakota',
     'OH' => 'Ohio',
     'OK' => 'Oklahoma',
     'OR' => 'Oregon',
     'PW' => 'Palau',
     'PA' => 'Pennsylvania',
     'PR' => 'Puerto Rico',
     'RI' => 'Rhode Island',
     'SC' => 'South Carolina',
     'SD' => 'South Dakota',
     'TN' => 'Tennessee',
     'TX' => 'Texas',
     'UT' => 'Utah',
     'VT' => 'Vermont',
     'VI' => 'Virgin Island',
     'VA' => 'Virginia',
     'WA' => 'Washington',
     'WV' => 'West Virginia',
     'WI' => 'Wisconsin',
     'WY' => 'Wyoming'
   }
   @state_abbr[abbr.upcase]
 end
 
end
