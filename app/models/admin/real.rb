class Admin::Real < ActiveRecord::Base

  def self.initialize
    
    # create the roles
    Badges::Role.create(:name => "authenticated")
    Badges::Role.create(:name => "admin")
    Badges::Role.create(:name => "registered_voter")
    Badges::Role.create(:name => "group_owner")
    Badges::Role.create(:name => "group_member")
    Badges::Role.create(:name => "article_owner")
    Badges::Role.create(:name => "representative")
    
    # create the privileges
    Badges::Privilege.create(:name => "manage badges")
    Badges::Privilege.create(:name => "manage districts")
    Badges::Privilege.create(:name => "create articles")
    Badges::Privilege.create(:name => "edit article")
    Badges::Privilege.create(:name => "finalize article")
    Badges::Privilege.create(:name => "progress article")
    Badges::Privilege.create(:name => "support articles")
    Badges::Privilege.create(:name => "manage pages")
    Badges::Privilege.create(:name => "rate comments")
    
    # create the Real Democracy district
    District.create(:name => "Real Democracy")
    
    # create the admin user
    admin = User.create(:name => "Thomas Jefferson", :email => "admin@hungrychild.org", :zip => "00000", :login => "/", :password => "root")
    admin.reload
    admin.grant_role("admin")
    
  end

end