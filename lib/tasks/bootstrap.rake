namespace :bootstrap do
  desc "Initializes the Root user Account"
  task :user_from_input => [:environment, :default_badges] do
    puts "{Setup your root account"
    name = ask "Displayed Name: "
    email = ask "Email address: "
    username = ask "Login: "
    password = ask "Password: "
    if User.exists?(:id => 1)
      user = User.find 1
      user.update_attributes( :name => name, :email => email, :login => username, :password => password )
    else
      user = User.create(:id => 1, :name => name, :email => email, :login => username, :password => password)
    end
    user.grant_role('admin')
    puts "Root account setup}"
  end
  task :default_user => [:environment, :default_badges] do
    name = "Eric Weinert"
    email = "void@democracyuniversal.com"
    username = "admin"
    password = "democracy"
    if User.exists?(:id => 1)
      user = User.find 1
      user.update_attributes( :name => name, :email => email, :login => username, :password => password )
    else
      user = User.create(:id => 1, :name => name, :email => email, :login => username, :password => password)
    end
    user.grant_role('admin')
    puts "Default root account setup"
    puts "username: #{username}"
    puts "password: #{password}"
  end

  desc "Create the default comment"
  task :community_from_input => :environment do
    name = ask "Create legislature named: "
    Community.create( :name => name )
  end
  desc "Create the default comment"
  task :default_community => :environment do
    name = "Democracy Universal"
    Community.create( :name => name )
  end
  
  desc "Create the default Badges"
  task :default_badges => :environment do
    puts "{Creating default badges"
    ["authenticated", "admin", "registered_voter", "article_owner", "representative", "clerk", "chair"].each do |role|
      Badges::Role.create(:name => role)
    end
    privilege_to_role('manage badges', 'admin')
    privilege_to_role('impersonate users', 'admin')
    privilege_to_role('manage communities', 'admin')
    privilege_to_role('manage community', 'chair')
    privilege_to_role('manage constituents', 'representative')
    privilege_to_role('edit article', 'article_owner', 'representative', 'clerk')
    privilege_to_role('finalize article', 'article_owner')
    privilege_to_role('kill article', 'article_owner', 'chair', 'representative', 'clerk')
    #privilege_to_role('')
    puts "Badges created}"
  end
  
  def privilege_to_role(privilege, *rolls)
    Badges::Privilege.create(:name => privilege) do |p|
      rolls.each do |roll|
        r = Badges::Role.find_by_name(roll)
        Badges::RolePrivilege.create(:role=>r,:privilege=>p)
      end
    end
  end
  def ask message
    print message
    STDIN.gets.chomp
  end

  desc "Run all bootstrapping tasks"
  task :all => [:default_user, :default_community]
end
