class CreateDefaultData < ActiveRecord::Migration
  def self.up
    Badges::Role.create(:name=>Badges::Config.default_user_role.to_s)
    Badges::Role.create(:name=>Badges::Config.default_admin_role.to_s)
  
    Badges::Privilege.create(:name=>"manage authorization")
    Badges::Privilege.create(:name=>"manage privileges")
    Badges::Privilege.create(:name=>"manage roles")
  end

  def self.down
    Badges::Role.find(:first, :conditions=>{:name=>Badges::Config.default_user_role.to_s}).destroy
    Badges::Role.find(:first, :conditions=>{:name=>Badges::Config.default_admin_role.to_s}).destroy
  end
end
