require 'cgi'
require 'ruby-debug'

class CertificationController < ApplicationController
  
  def ssl_required? 
    true 
  end
  
  before_filter :login_required, :only => [:redeem, :destroy]
  before_filter :valid_api_user, :only => [:create]
  
  def show
    redirect_to "/"
  end
  
  def create
    external_source = params[:api_user]

    name = params[:name]
    districts = ActiveSupport::JSON.decode(params[:memberships])
    
    certs=[]
    districts.each do |external_id, community, district|
      if com = Community.find_by_name(community)
        if dis = com.districts.find_by_name(district)
          certs << Certification.generate_or_retrieve_certificate( dis.id, name, external_source, external_id )
        end
      end
    end
    
    render :json => certs.to_json(:only => [:id, :external_id, :district_id, :certification_number, :certification_pin])
  end
  
  def redeem
    if cert = Certification.find_by_certification_number( params[:certificate] )
      if cert.certification_pin == params[:keycode]
        if cert.assign_to current_user
          flash[:notice] = "<p>Certification Successful</p><p>You are now a Certified Member of #{ cert.district.full_name }</p>"
          redirect_to cert.district
          return true
        end
      end
    end
    flash[:error] = "<p>Certification failed</p>"
    redirect_to '/'
  end
  
  def destroy
    cert = Certification.find(params[:id])
    if current_user.has_privilege?('certify users', cert.community)
      cert.end
      flash[:notice] = "<p>Certification of #{cert.certified_name || cert.user.name} revoked</p>"
    else
      flash[:error] = "<p>Revocation failed</p>"
    end
    redirect_to :back
  end
  
  private
  def valid_api_user
    user = ApiUser.find_by_login params[:api_user]
    unless user && params[:api_key] == user.password
      render :text => "You are not authorized"
    end
  end
  
end
