class ProposalsController < ApplicationController
  
  def index
    if params[:id]
      self.current_district = District.find(params[:id])
    end
    if current_district
      @list = current_district.articles.if_certified(certification_filter?).focuses.all(:order => 'focus_count DESC, support_count DESC')
      #redirect_to agenda_district_path(current_district)
      render :template => 'shared/list'
    else
      redirect_to agenda_community_path(current_community)
    end
  end
  
end
