require 'ruby-debug'

class Certification < ActiveRecord::Base
  
  belongs_to :community
  belongs_to :district, :counter_cache => :certifications_count
  belongs_to :user
    
  #validates_uniqueness_of :user_id, :scope => [:district_id, :user_id]
  
  named_scope :certified, :conditions => 'certification_number IS NOT NULL'
  named_scope :active, :conditions => 'start_date IS NOT NULL AND end_date IS NULL'
  named_scope :available, :conditions => 'end_date IS NULL'
  
  def used?
    !free?
  end
  def free?
    user.nil?
  end
  
  def self.generate_or_retrieve_certificate(district_id, name, external_source, external_id)
    # make sure district_id is the district.id. this fucked me up when i sent a district object.
    if cert = find(:first, :conditions => { :district_id => district_id, :external_source => external_source, :external_id => external_id})
      return cert
    else
      generate_certificate(district_id, name, external_source, external_id)
    end
  end
  
  # probably a bug. should be district, not district_id ?
  def self.generate_certificate(district_id, name, external_source, external_id)
    community_id = District.find(district_id).community_id
    create(:certification_number => random, :certification_pin => random, :district_id => district_id, :community_id => community_id, :certified_name => name, :external_source => external_source, :external_id => external_id)
  end
  
  def self.generate_blank_certificate(district_id)
    community_id = District.find(district_id).community_id
    create(:district_id => district_id, :community_id => community_id)
  end
  
  def self.certify(district, user)
    #find the certification if it exists
    cert = Certification.first(:conditions => { :district_id => district.id, :user_id => user.id })
    cert.authorize if cert
    #generate a new one if it doesn't
    cert ||= district.generate_blank_certification
    
    cert.assign_to user
  end
  
  def self.end(district, user)
    cert = Certification.first(:conditions => { :district_id => district.id, :user_id => user.id })
    cert.end
  end
  def end
    update_attribute('end_date', Time.now)
  end
  
  def assign_to(new_user)
    # block overwriting if user exists (ie, it has been used)
    return nil if used?
    # assign it to the user and activate it by starting the time
    self.user = new_user
    self.start_date = Time.now
    self.save
  end
  
  def certified?
    certification_number.exists?
  end
  
  private
  def new
  end
  def self.random
    "a" + rand(999999999999).to_s.rjust(12, '0')
  end
  def random
    "a" + rand(999999999999).to_s.rjust(12, '0')
  end
  
end
