class IdeasController < ApplicationController
    
  def index
    
    if current_district
      @list = current_district.articles.drafts#.tag_filter(sieve.tags) .if_certified( certification_filter? )
    else
      @list = current_community.articles.drafts#.tag_filter(sieve.tags) .if_certified( certification_filter? )
    end
    
    respond_to do |format|
      #format.xml { render :xml => @list.to_xml(:methods => [:support_count]) }
      format.html { render :template => 'shared/list' }
      #format.xhr { render :xml => @list.to_xml }
    end
  end
  
end