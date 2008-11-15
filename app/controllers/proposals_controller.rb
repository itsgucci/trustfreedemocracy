class ProposalsController < ApplicationController
  
  def index
    if current_district
      redirect_to agenda_district_path(current_district)
    else
      redirect_to agenda_community_path(current_community)
    end
  end
  
end
