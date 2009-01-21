module CommunitiesHelper
  
  def link_to_district_or_manage(district, admin=false)
    rep = district.representative ? " - " + district.representative.name : ""
		if admin
			"<li>#{ link_to_remote district.name + rep , :url => {:controller => 'districts', :action => 'manage_district', :id => district} }</li>"
	  else
			"<li>#{ link_to( district.name + " - " + district.description, district ) }</li>"
		end
  end
  
  def potential_reps_collection
    @pot_reps ||= ([[nil, "none"]] + User.find(:all).map {|user| [user.id, user.facebook_id] }).to_json
  end
  
end
