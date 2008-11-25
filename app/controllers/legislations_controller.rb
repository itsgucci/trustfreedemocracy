class LegislationsController < ApplicationController  
      
  def index
    @list = current_community.articles.if_certified( certification_filter? ).legislations.paginate(:page => params[:page], :per_page => 7)#.tag_filter(sieve.tags)
    
    render :template => 'shared/list'
  end

  def update_filter
    session[:lfilter] = params[:filter]
  end
  
  def add_tag
    if request.xhr?
      @object = Legislation.find(params[:id])
      @object.tag_with(params[:tag], params[:interest_id], @current_user)
      render :update do |page|
        page.replace_html 'module_area', :partial => 'modules/describe/describe', :object => @object
      end
    end
  end
  
end
