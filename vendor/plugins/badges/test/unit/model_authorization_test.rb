require File.dirname(__FILE__) + '/../test_helper'

module Badges
  class SomeProject < ActiveRecord::Base
    set_table_name "badges_test_projects"
    
    badges_authorizable_object
    
    attr_accessor :peer, :owner

    privilege_required 'can create project'=>:create, 'can view project'=>:find

    privilege_required 'can update project'=>:update, :on=>:peer, :user=>:owner
            
  end

  class ModelAuthorizationTest < Test::Unit::TestCase
  
    def test_privilege_required_fails
      tu = Badges::TestUser.create(:username =>'tu')
      Thread.current['current_user'] = tu
      
      assert_raise SecurityError do
        Badges::SomeProject.create(:name=>'this should fail')
      end
    end

    def test_privilege_required_succeeds
      tu = Badges::TestUser.create(:username =>'tu')
      r = Badges::Role.create(:name=>'foo')
      p = Badges::Privilege.create(:name=>"can create project")
      rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
      tu.grant_role('foo')
      Thread.current['current_user'] = tu
      sp = Badges::SomeProject.create(:name=>'this should work')
      assert !sp.new_record?
    end
    
    def test_on_and_user_options
      tu1 = Badges::TestUser.create(:username =>'tu1')
      r1 = Badges::Role.create(:name=>'foo')
      p1 = Badges::Privilege.create(:name=>"can create project")
      rp1 = Badges::RolePrivilege.create(:role=>r1, :privilege=>p1)
      Thread.current['current_user'] = tu1
      tu1.grant_role('foo')

      #grant the role on a different project for a different user
      sp2 = Badges::SomeProject.create(:name=>'this should also work')
      tu2 = Badges::TestUser.create(:username =>'tu2')
      r2 = Badges::Role.create(:name=>'bar')
      p2 = Badges::Privilege.create(:name=>"can update project")
      rp2 = Badges::RolePrivilege.create(:role=>r2, :privilege=>p2)
      tu2.grant_role('bar', sp2)

      sp1 = Badges::SomeProject.create(:name=>'this should work')
      
      #ok, now try to update w.o role, and it won't work
      sp1.owner = tu1
      sp1.peer = sp1
      sp1.name = 'a new name'
      assert_raise SecurityError do
        sp1.save!
      end

      
      # puts r2.privileges.inspect
      # puts tu2.privileges(sp2).inspect
      # puts tu2.user_roles.inspect

      sp1.owner = tu1
      sp1.peer = sp1
      sp1.name = 'a new name'
      assert_raise SecurityError do
        sp1.save!
      end

      #now use the right authorizable and user
      sp1.owner = tu2
      sp1.peer = sp2
      sp1.name = 'another name'
      assert_nothing_raised do
        sp1.save!
      end

    end
    
    def test_find_protected
      tu = Badges::TestUser.create(:username =>'tu')
      Thread.current['current_user'] = tu

      #test the various ways to call find
      assert_raise SecurityError do
        Badges::SomeProject.find(:all)
      end

      assert_raise SecurityError do
        Badges::SomeProject.find(:first)
      end

      assert_raise SecurityError do
        Badges::SomeProject.find(1)
      end

      assert_raise SecurityError do
        Badges::SomeProject.find_by_name('some name')
      end

      assert_raise SecurityError do
        Badges::SomeProject.find_all_by_name('some name')
      end

      assert_raise SecurityError do
        Badges::SomeProject.find_or_create_by_name('some name')
      end

      assert_raise SecurityError do
        Badges::SomeProject.find_by_sql('select * from badges_test_projects')
      end

    end

    def test_authorization_checker
      tu = Badges::TestUser.create(:username =>'tu')
      r = Badges::Role.create(:name=>'foo')
      p = Badges::Privilege.create(:name=>"can create project")
      rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
      tu.grant_role('foo')

      Thread.current['current_user'] = tu
      sp = Badges::SomeProject.new(:name=>'not saving, wont trigger the callback')
      ac = Badges::ModelAuthorization::AuthorizationChecker.new
      ac.add_to_required_privileges(:before_create, 'can create project', {})
      assert ac.callback_check_model_privilege(:before_create, sp)
    end

  end

end
