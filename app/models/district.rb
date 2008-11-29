class District < ActiveRecord::Base
  
  belongs_to :community
  
  has_many :articles
  
  has_many :endorsements, :dependent => :destroy
  has_many :endorsers, :through => :endorsements, :source => :user
  
  has_many :certifications, :dependent => :destroy
  has_many :users, :through => :certifications, :conditions => "start_date IS NOT NULL AND end_date IS NULL"
  has_many :members, :through => :certifications, :source => :user, :conditions => "certifications.start_date IS NOT NULL AND certifications.end_date IS NULL"
  
  belongs_to :representative, :foreign_key => :user_id, :class_name => "User"
  
  has_many :actions, :order => "created_at DESC"
    
  has_many :pages, :as => :pageable
  
  has_one :top_priority, :class_name => "Article"
  
  badges_authorizable_object
  
  acts_as_commentable
  
  #named_scope :active_members, :include => :certifications, :conditions => 'certifications.ended_at IS NOT NULL'
  #named_scope :certified_members, :include => :certifications, :conditions => 'certifications.ended_at IS NOT NULL AND certification.certificate IN NOT NULL'
          
  validates_presence_of :name
  
  def self.find_all_by_zip(zip)
    districts = []; state = ""
    response = Hpricot(open("http://services.sunlightlabs.com/api/districts.getDistrictsFromZip.xml?apikey=e0a7a09436fa8c75c7efff35519e9067&zip=#{ zip }"))
    (response/:district).each do |district|
      state = state_abbr((district/:state).html)
      districts << District.find( :all, :conditions => ["name LIKE ?", state + ' ' + (district/:number).html + '%'])
    end
    return districts.flatten
  end
  
  def description
    read_attribute('description') || ""
  end
  
  
  def last_synchronized
    community.last_synchronized
  end
  
  def generate_blank_certification
    certifications.generate_blank_certificate
  end
  
  def member?(user)
    return false if user.nil?
    return false if user == :false
    users.include? user
  end
  def certified?(user)
    return false if user.nil?
    return false if user == :false
    cert = certifications.active.find_by_user_id_and_district_id(user.id, id)
    return false if cert.blank?
    !cert.certification_number.blank?
  end
  
  def register(user, certificate, keycode)
    return false unless user
    unless certificate.blank? && keycode.blank?
      #if one exists, associate it with that.
      cert = Certification.find_by_certification_number certificate
      if cert && cert.certification_pin == keycode
        cert.assign_to user
      end
    else
      return false if member?( user ) # block multiple memberships. one ring to rule them all.
      #if it doesn't exist, issue them one.
      Certification.transaction do
        cert = Certification.generate_blank_certificate(id)
        cert.assign_to user
      end
    end
  end
  def certify(user)
    return false unless user
    return false if certified?( user ) # block multiple memberships. one ring to rule them all.
    certifications.certify self, user
  end
  def leave(user)
    Certification.end(self, user)
    # decrement counter cache
  end
  
  def article_types
    community.article_types
  end
  def article_type
    community.article_type
  end
  
  # todo: remove this
  # def top_priority
  #   article = articles.focuses.first(:order => 'focus_count DESC, support_count DESC')
  #   return nil if article.nil?
  #   article.focus_count == 0 ? nil : article
  # end
  
  def top_supported_articles(number = 1)
    #todo clean this up. last is dodgy at best.
    articles.all(:order => 'support_count').first(number)
  end
  
  def to_s
    name
  end
  
  def full_name
    community.name + ": " + name
  end
  
  def population
    #certifications_count
    members.size
  end
  def count
    population
  end
  
  def representative=(user)
    #revoke old badges
    representative.revoke_role( 'representative', self ) if representative
    if user
      write_attribute( :user_id, user.id)
      if save
        role_granted 'representative', user
      end
    else
      update_attribute( :user_id, nil )
    end
    reload
  end
  
  def representative_affinity
    100
  end
  
  def articles_in_comite
    articles.in_comite
  end
  
  def default_article_type
    article_types[1]
  end
  
  def website
    pages.first
  end
  def blog
    comments
  end
  
end
