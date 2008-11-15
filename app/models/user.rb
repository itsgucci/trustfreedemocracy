require 'digest/sha1'
class User < ActiveRecord::Base
  
  badges_authorized_user
  
  acts_as_commentable
  
  has_many :articles
  
  has_many :votes
    
  has_many :endorsements, :dependent => :destroy
  has_many :endorsed_articles, :through => :endorsements, :source => :article

  has_many :articles_supporters, :dependent => :destroy
  has_many :supported_articles, :through => :articles_supporters, :source => :article

  has_many :notifications
  
  has_many :certifications, :dependent => :destroy
  has_many :districts, :through => :certifications
  has_many :communities, :through => :certifications
  
  has_many :communities, :through => :districts, :source => :users
  
  has_many :pages, :as => :pageable
  
  has_many :taggings
  has_many :tags, :through => :taggings, :select => "DISTINCT tags.*"
  
  has_many :comite_members
  has_many :comites, :through => :comite_members
  
  has_many :bookmarks
  has_many :objects, :through => :bookmarks
    
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :email, :name
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email, :case_sensitive => false
  before_save :encrypt_password
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :name, :zip
  
  named_scope :system_generated_users, :conditions => "login = ''"
  named_scope :authenticated_users, :conditions => "login != ''"
  
  define_index do
    index :name
    
    has community_id
    has district_id
  end
  
  def district_memberships
    certifications.active(:include => :district).map {|cert| cert.district }
  end
  def certified_district_memberships
    certifications.active.certified(:include => :district).map {|cert| cert.district }
  end
  def community_memberships
    certifications.active(:include => :community).map {|cert| cert.community }
  end
  def certified_community_memberships
    certifications.active.certified(:include => :community).map {|cert| cert.community }
  end
  
  def number
    "U." + id.to_s
  end
  
  def contribution_total
    100
  end

  def endorsed_article
    endorsed_articles.find(:first, :conditions => "ended_at is NULL")
  end
  
  def legislative_accuracy
    if votes.empty?
      0
    else
      accuracy = 0
  		votes.each do |vote|
  		  accuracy += 1 if vote.vote == vote.article.passed?
  		end
  		accuracy / votes.size
  		#votes.count(:conditions => "vote.article.stage < 3")
  		# would have to have a database level call for passed to replace with the above method
		end
  end
    
  def focus(district)
    endorsements.find(:first, :conditions => ["ended_at is NULL and district_id = ?", district.id])
  end
  def top_priorities(district = nil)
    if district
      focus(district)
    else
      endorsements.find(:all, :conditions => ["ended_at is NULL"])
    end
  end
  
  def articles_authored
    articles
  end
  
  def blog
    comments.find_all_by_category_code(4).reverse
  end
  
  def congruency(user)
    return 0 if votes.empty? || user.votes.empty?
    union = votes | user.votes
    intersection = votes & user.votes
    intersection.size / union.size
    
    # wrong! because vote1 != vote2; must check vote.vote && vote.voteable for equality of whole
  end
  
  
  # todo. these should show how aligned the user is with the group. and calculate the general interst and then compare it to you. if there is a strong corolation, there is a stronger interest.
  def interest_in_article(article)
    
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
    
end
