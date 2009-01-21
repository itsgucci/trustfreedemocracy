require 'rubygems'
require 'git'

class Article < ActiveRecord::Base
  
  acts_as_commentable
  acts_as_taggable
  acts_as_voteable
  
  badges_authorizable_object
  
  validates_presence_of :article_type_id
  
  belongs_to :article_text
  has_many :article_texts
    
  belongs_to :district
  belongs_to :community  
  has_one :legislation
  has_many :actions, :order => 'created_at DESC'
  has_many :rolls, :order => 'created_at DESC', :include => :roll_votes
  
  belongs_to :author, :foreign_key => :user_id, :class_name => "User"
  
  has_many :articles_supporters, :dependent => :destroy
  has_many :supporters, :through => :articles_supporters, :source => :user
  
  has_many :endorsements, :dependent => :destroy, :conditions => { :ended_at => nil }
  has_many :endorsers, :through => :endorsements, :source => :user
    
  has_many :comite_stages
  has_many :comites, :through => :comite_stages

  named_scope :certified, :conditions => { :certified => true }
  
  named_scope :if_certified, lambda { |certified| certified ? { :conditions => { :certified => true } } : {} }
  named_scope :tag_filter, lambda { |tag_array| { :include => :taggings, :conditions => ['taggings.tag_id IN (?)', tag_array] } }
  
  #named_scope :active_endorsers, :include => :endorsements, :conditions => ['endorsements.ended_at = ?', nil]
  
  named_scope :most_supported, lambda { |number| {:order => "support_count ASC", :limit => number} }
  
  define_index do
    indexes number
    indexes title
    indexes summary
    indexes text
    
    has community_id
    has support_count
    has focus_count
  end
  
  def text(specific_version = false)
    if specific_version
      if article_text = article_texts.find_by_version(specific_version)
        article_text.text
      else
        nil
      end
    else
      article_text_id ? ArticleText.find(article_text_id).text : nil
    end
  end
  def text=(text)
    current_article_text = article_text
    current_article_text ||= article_texts.new #create if not found
    current_article_text.version = version if version && current_article_text.new_record?
    current_article_text.text = text
    current_article_text.save
  end
  def edit_version(version, text)
    current_article_text = article_texts.find_by_version(version) || article_texts.new
    current_article_text.version = version if current_article_text.new_record?
    current_article_text.text = text
    current_article_text.save
  end
  def versions
    article_texts.map(&:version)
  end
  def set_current_version(version)
    unless current_article_text = article_texts.find_by_version(version)
      current_article_text = article_texts.create(:version => version)
    end
    update_attribute('article_text_id', current_article_text.id)
  end
  def current_version
    article_text.version
  end
  
  def cosponsors
    []
    # todo, fix this stub. 
  end
  
  def name
    title.blank? ? "No Title" : title
  end
  
  def cost_per_taxpayer
    return 0 if cost.blank?
    cost.to_f / community.tax_population
  end
  
  def article_type
    #oh joy. a minus one bug waiting to happen.
    ArticleType.list[article_type_id - 1]
  end
  
  def savings?
    cost < 0
  end
  
  def budget
    cost || 0
  end
  
  def supported_by?(supporter)
    supporters.include? supporter
  end
  def endorsed_by?(user)
    endorsements.exists?(:ended_at => nil, :user_id => user.id)
  end
  
  def passed?
    if legislation && legislation.closed?
      votes_for > votes_against
    else
      nil
    end
  end
  
  def add_support(user)
    #todo repair this to work for multiple districts!
    if !supported_by?(user)# && user.has_privilege?('support articles', district)
      supporters << user
      reload
      return true
    end
    false
  end
  def withdraw_support(user)
    # you should always be able to withdraw support.
    # this should instead add a ending date to the current support of this article instead of removing it. we want to keep a record of support, not have stuff "disappear"
    Article.transaction do
      supporters.delete user
      Article.decrement_counter('support_count', self.id)
    end
    reload
    true
  end
  
  def notify_supporters(message)
    supporters.each do |supporter|
      supporter.notifications << Notification.new(:message => message, :from_user_id => 1)
    end
  end
  
  #this should be in the acts_as_commentable plugin. NOT here
  def comment_count
    comments.size
  end
  
  def support_percentage
    return 0 if support_count == 0
    ((support_count.to_f / community.tax_population) * 100)
  end
  def support_entity
    if draft? || focus?
      district
    else
      community
    end
  end
  def focus_percentage
    return 0 if focus_count == 0
    ((focus_count.to_f / district.population) * 100)
  end
  
  # the following two methods are hacks.
  # def focus_count
  #     endorsements.active.size
  #   end
  #   def support_count
  #     supporters.size
  #   end
  
  def endorse(user)
    unendorse(user)
    if focus?
      Endorsement.create(:article_id => id, :user_id => user.id, :district_id => self.district_id)
    else
      false
    end
  end
  
  def unendorse(user)
    if endorsement = Endorsement.first(:conditions => ["user_id = ? AND district_id = ? AND ended_at IS NULL", user.id, self.district_id])
      Article.transaction do
        endorsement.update_attribute('ended_at', Time.now)
        Article.decrement_counter('focus_count', self.id)
      end
      true
    end
  end
  
  def voted?(user)
    return false unless user
    return false if user == :false
    !user.votes.first(:conditions => "voteable_type = 'Article' AND voteable_id = #{id} AND vote is not null").nil?
  end
  def ratified_by?(user)
    return false unless user
    return false if user == :false
    user.votes.exists? :voteable_type => 'Article', :voteable_id => id, :vote => 1
  end
  def opposed_by?(user)
    return false unless user
    return false if user == :false
    user.votes.exists? :voteable_type => 'Article', :voteable_id => id, :vote => 0
  end
  def present_by?(user)
    return false unless user
    return false if user == :false
    user.votes.exists? :voteable_type => 'Article', :voteable_id => id, :vote => 2
  end
  def votes_present
    votes.all(:conditions => { :voteable_type => 'Article', :voteable_id => id, :vote => 2 }).size
  end
  
  def represented?(user, representative)
    return false unless voted?(user) && voted?(representative)
    if ratified_by?(user) && ratified_by?(representative)
      true
    elsif opposed_by?(user) && opposed_by?(representative)
      true
    elsif present_by?(user) && present_by?(representative)
      true
    else
      false
    end
  end

  def assigned_to_comite?
    !comites.empty?
  end
  
  def number
    read_attribute('number') || article_type.short_name + "." + id.to_s
  end
  
  def discussion
    comments.find_all_by_category_code(0)
  end
  def reports
    comments.find_all_by_category_code(3)
  end
  def add_report(title, content)
    #this should be the districts admin account
    return true if comments << Comment.new( :category_code => 3, :title => title, :comment => content, :user_id => 1 )
    false
  end
  
  def author=(user)
    author.revoke_role("article_owner", self) if author
    if update_attribute( :user_id, user.id)
      role_granted 'article_owner', user
    end
  end
  def author_name
    author ? author.name : "Unknown"
  end
  
  def update_budget(budget)
    #clean it as best as possible
    budget.gsub!(/[\$,a-zA-Z]/,'')
    update_attribute('cost', budget)
  end
  def cost=(amount)
    amount.gsub!(/[\$,a-zA-Z]/,'')
    write_attribute('cost', amount)
  end
  
  def finalize_draft
    if draft?
      if update_attribute('stage', 2)
        action = "#{ title } has been finalized and is now a possible Priority"
        actions << Action.new(:community_id => community_id, :district_id => district_id, :house => "O", :action => action, :processed => true)
      end
    end
  end
  def move_to_comite
    if update_attribute('stage', 3)
      action = "#{ title } has entered Legislature"
      actions << Action.new(:community_id => community_id, :district_id => district_id, :house => "O", :action => action, :processed => true)
    end
  end
  def move_to_vote
    if update_attribute('stage', 4)
      action = "#{ title } is now open for Vote"
      actions << Action.new(:community_id => community_id, :district_id => district_id, :house => "O", :action => action, :processed => true)
    end
  end
  def kill
    if update_attribute('stage', 6)
      action = "#{ title } has been Killed"
      actions << Action.new(:community_id => community_id, :district_id => district_id, :house => "O", :action => action, :processed => true)
    end
  end
  
  def unknown?
    stage == 0
  end
  def draft?
    stage == 1
  end
  def focus?
    stage <= 2
  end
  def in_comite?
    stage == 3
  end
  def legislation?
    stage == 4
  end
  def law?
    stage == 5
  end
  def dead?
    stage == 6
  end
  def to_exec?
    stage == 7
  end
  def signed?
    stage == 8
  end
  def vetoed?
    stage == 9
  end
  def overridden?
    stage == 10
  end
  
  named_scope :unknown, :conditions => "stage = 0"
  named_scope :drafts, :conditions => "stage = 1"
  named_scope :focuses, :conditions => "stage = 2"
  named_scope :in_comite, :conditions => "stage = 3"
  named_scope :legislations, :conditions => "stage = 4"
  named_scope :laws, :conditions => "stage = 5"
  named_scope :dead, :conditions => "stage = 6"
  named_scope :to_exec, :conditions => "stage = 7"
  named_scope :signed, :conditions => "stage = 8"
  named_scope :vetoed, :conditions => "stage = 9"
  named_scope :overridden, :conditions => "stage = 10"
  
  def stage_name
    Article.stage_names.at stage
  end
  def self.stage_names
    ["unknown", "Development", "Priority", "In Legislature", "Open for Vote", "Enacted as Law", "Dead", "To Executive", "Signed", "Veto", "OverRide"]
  end
  
end