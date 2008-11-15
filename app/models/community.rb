class Community < ActiveRecord::Base
  
  badges_authorizable_object
  
  acts_as_tree
  
  has_many :certifications, :dependent => :destroy
  has_many :users, :through => :certifications
  has_many :members, :through => :certifications, :source => :user, :conditions => "certifications.start_date IS NOT NULL AND certifications.end_date IS NULL"
  has_many :certified_members, :through => :certifications, :source => :user, :conditions => "certifications.start_date IS NOT NULL AND certifications.end_date IS NULL AND certifications.certification_number IS NOT NULL"
  
  has_many :districts, :order => "name"
  has_many :comites
  has_many :articles, :include => :author, :order => "support_count DESC"
  
  has_many :representatives, :through => :districts
    
  belongs_to :chairperson, :foreign_key => :user_id, :class_name => "User"
  
  has_many :actions, :order => 'created_at DESC'
  
  has_many :pages, :as => :pageable
  
  acts_as_commentable
  
  named_scope :visible, :conditions => { :visible => true }
    
  attr_accessor :style
  
  def calendar_page
    if page = pages.first
      return page
    else
      pages.create
    end
  end
  def charter_page
    pages.at 2
  end
  
  def minutes
    comments.all(:conditions => { :category_code => 5 }, :order => "created_at DESC")
  end
  
  def in_session?
    true
  end
  
  def article_types
    ArticleType.list
  end
  
  def self.roots
    self.find(:all, :conditions=>["parent_id = ?", 0])
  end

  def level
    self.ancestors.size
  end
  
  def population
    members.size
  end
  
  def budget
    #articles.laws.sum { |x| x.budget }
    0
  end
  
  def district_represented(representative)
    districts.all(:include => :representative).each do |district|
      return district if district.representative == representative
    end
    nil
  end
  
  def member?(user)
    return false if user.nil?
    return false if user == :false
    members.include?(user)
  end

  def certified?(user)
    return false if user.nil?
    return false if user == :false
    certified_members.include?(user)
  end

  def chairperson=(user)
    chairperson.revoke_role( 'chairperson', self ) if chairperson
    write_attribute( :user_id, user.id)
    if save
      role_granted 'chairperson', user
    end
  end
  
  def clerks
    clerk_role = Badges::Role.find_by_name('Clerk')
    badges = Badges::UserRole.all( :conditions => { :role_id => clerk_role.id, :authorizable_type => 'Community', :authorizable_id => id } )
    User.find badges.map(&:user_id)
  end
  def add_clerk(user)
    role_granted('clerk', user)
    reload
  end
  def remove_clerk(user)
    role_revoked('clerk', user)
    reload
  end
  
end