class IdeasController < ApplicationController
    
  def index
    
    if current_district
      @list = current_district.articles.if_certified( certification_filter? ).drafts.paginate(:per_page => 7, :page => params[:page])#.tag_filter(sieve.tags)
    else
      @list = current_community.articles.if_certified( certification_filter? ).drafts.paginate(:per_page => 7, :page => params[:page])#.tag_filter(sieve.tags) 
    end
    
    respond_to do |format|
      #format.xml { render :xml => @list.to_xml(:methods => [:support_count]) }
      format.html { render :template => 'shared/list' }
      #format.xhr { render :xml => @list.to_xml }
    end
  end
  
end