require File.dirname(__FILE__) + '/../test_helper'

module Badges

  class AuthorizedTest < Test::Unit::TestCase
  
    attr_accessor :test_user, :test_project, :roles
  
    def setup
      setup_data
    end
  
    def test_user_roles_and_roles
      tu = Badges::TestUser.create(:username =>'tu')
      r = Badges::Role.create(:name=>'foo')
      ur = Badges::UserRole.create(:user=>tu, :role=>r)
      assert_equal [r], tu.roles
    end

    def test_grant_role
      tu = Badges::TestUser.create(:username =>'tu')
  
      tu.grant_role :admin
      assert_equal 1, tu.roles.size
      assert_equal 1, tu.user_roles.size
      assert_equal tu.roles.first.name, 'admin'
    
      tu.grant_role :member
      assert_equal 2, tu.roles.size
      assert_equal 2, tu.user_roles.size
    end

    def test_grant_role_no_dupe_role_create

      r = Badges::Role.create(:name=>'nodupe')
      tp = Badges::TestProject.create(:name =>'tp')
      tu = Badges::TestUser.create(:username =>'tu')  
      tu.grant_role :nodupe
      tu.grant_role :nodupe, tp
      tu.grant_role :nodupe, Badges::TestProject
    
      roles = Badges::Role.find(:all, :conditions=>{:name=>'nodupe'})
      assert_equal 1, roles.size
    
    end

    def test_grant_role_on_authorizable_instance
      tu = Badges::TestUser.create(:username =>'tu')
      tp = Badges::TestProject.create(:name =>'tp')
  
      tu.grant_role :admin, tp
      assert_equal 1, tu.roles.size
      assert_equal 1, tu.user_roles.size
      assert_equal tu.roles.first.name, 'admin'
    
      tu.grant_role :member, tp
      assert_equal 2, tu.roles.size
      assert_equal 2, tu.user_roles.size
    end

    def test_grant_role_on_authorizable_class
      tu = Badges::TestUser.create(:username =>'tu')
  
      tu.grant_role :admin, Badges::TestProject
      assert_equal 1, tu.roles.size
      assert_equal 1, tu.user_roles.size
      assert_equal tu.roles.first.name, 'admin'
    
      tu.grant_role :member, Badges::TestProject
      assert_equal 2, tu.roles.size
      assert_equal 2, tu.user_roles.size
    end

    def test_revoke_role
      tu = Badges::TestUser.create(:username =>'tu')
  
      tu.grant_role :admin
      assert_equal 1, tu.roles.size
  
      tu.revoke_role :admin
      assert_equal 0, tu.roles.size
      assert_equal 0, tu.user_roles.size
    end

    def test_revoke_role_on_authorizable
      tu = Badges::TestUser.create(:username =>'tu')
      tp = Badges::TestProject.create(:name =>'tp')
  
      tu.grant_role :admin, tp
      assert_equal 1, tu.roles.size
  
      tu.revoke_role :admin
      assert_equal 1, tu.roles.size
  
      tu.revoke_role :admin, tp
      assert_equal 0, tu.roles.size
      assert_equal 0, tu.user_roles.size
    end
    
    def test_roles_on
      tu = Badges::TestUser.create(:username =>'tu')
      tp = Badges::TestProject.create(:name =>'tp')
      tu.grant_role :admin, tp
      tu.grant_role :member, tp
      
      admin = Badges::Role.find_by_name('admin')
      member = Badges::Role.find_by_name('member')
      assert tu.roles_on(tp).include?(admin)
      assert tu.roles_on(tp).include?(member)
    end

    def test_privileges

      assert_equal 2, @test_user.privileges.size
      assert @test_user.privileges.include?(@privileges['admin'])
      assert @test_user.privileges.include?(@privileges['authenticated'])
      assert !@test_user.privileges.include?(@privileges['member'])
      assert !@test_user.privileges.include?(@privileges['manager'])
    end

    def test_privileges_on_authorizable

      #do not have the privs for roles with no authorizable specified
      assert !@test_user.privileges.include?(@privileges['member'])
      assert !@test_user.privileges.include?(@privileges['manager'])
  
      #do have the privs for roles with authorizable specified
      assert @test_user.privileges(@test_project).include?(@privileges['member'])
      assert @test_user.privileges(@test_project).include?(@privileges['manager'])

      #do have the privs for roles with authorizable specified, using the class
      assert !@test_user.privileges(Badges::TestProject).include?(@privileges['member'])
      assert @test_user.privileges(Badges::TestProject).include?(@privileges['manager'])
    end

    def test_has_privilege?
      assert @test_user.has_privilege?('authenticated')
      assert @test_user.has_privilege?('admin')
      assert !@test_user.has_privilege?('member')
      assert !@test_user.has_privilege?('manager')
    end

    def test_has_privilege_on_authorizable

      assert @test_user.has_privilege?('authenticated', @test_project)
      assert @test_user.has_privilege?('admin', @test_project)
      assert @test_user.has_privilege?('member', @test_project)
      assert @test_user.has_privilege?('manager', @test_project)

      assert !@test_user.has_privilege?('member', Badges::TestProject)
      assert @test_user.has_privilege?('manager', Badges::TestProject)

    end

    def test_add_new_privilege_if_missing
      Badges::Config.create_when_missing = true
      tu = Badges::TestUser.create(:username =>'tu')
      assert_difference('Badges::Privilege.count') do
        tu.has_privilege?('create_this_it_does_not_exist')
      end
    end

    def test_add_new_privilege_if_missing_to_admin_role
      Badges::Config.create_when_missing = true
      r = Badges::Role.create(:name=>'default_admin')
      assert_equal r.privileges.size, 0
      p = Badges::Privilege.find(:first, :conditions=>'name = "create_this_it_does_not_exist"')
      assert_nil p

      Badges::Config.default_admin_role = 'default_admin'
      tu = Badges::TestUser.create(:username =>'tu')
      assert_difference('Badges::Privilege.count') do
        tu.has_privilege?('create_this_it_does_not_exist')
      end

      p = Badges::Privilege.find(:first, :conditions=>'name = "create_this_it_does_not_exist"')
      assert p

      assert_equal r.privileges.size, 1
      assert_equal r.privileges.first, p
            
    end

    def test_add_default_role_to_user
      r = Badges::Role.create(:name=>'default_role')
      Badges::Config.default_user_role = 'default_role'
      tu = Badges::TestUser.create(:username =>'tu')
      assert_equal tu.roles.size, 1
      assert_equal tu.roles.first, r
    end

    def test_authorizables
      tu = Badges::TestUser.create(:username =>'tu')
      
      tp = Badges::TestProject.create(:name =>'tp3')
      tu.grant_role('manager',tp)
      tu.grant_role('member',tp)
      tu.grant_role('authenticated',Badges::TestProject.create(:name =>'tp1'))
      tu.grant_role('member',Badges::TestProject.create(:name =>'tp2'))
      tu.grant_role('friend',Badges::TestUser.create(:username =>'tu2'))

      assert_equal 4, tu.authorizables.size
      assert_equal 1, tu.authorizables(Badges::TestUser).size
      assert_equal 4, tu.roles.size
    end
    
    private
  
    def setup_data
      @test_user = Badges::TestUser.create(:username =>'tu')
      @test_project = Badges::TestProject.create(:name =>'tp')
      @roles = {}
      @privileges = {}

      ['authenticated','admin','member','manager'].each{|r| @roles[r] = Badges::Role.create(:name=>r)}
             
      @roles.each_value do |r|
        @privileges[r.name] = Badges::Privilege.create(:name=>"#{r.name}")      
        Badges::RolePrivilege.create(:role=>r, :privilege=>@privileges[r.name])
      end

      Badges::UserRole.create(:role=>@roles['authenticated'], :user=>@test_user)
      Badges::UserRole.create(:role=>@roles['admin'],         :user=>@test_user)
      Badges::UserRole.create(:role=>@roles['member'],        :user=>@test_user, :authorizable=>@test_project)
      Badges::UserRole.create(:role=>@roles['manager'],       :user=>@test_user, :authorizable_type=>Badges::TestProject.to_s)
    end

  end
end