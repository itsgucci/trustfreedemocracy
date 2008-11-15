require File.dirname(__FILE__) + '/../test_helper'

module Badges
  class AuthorizableTest < Test::Unit::TestCase
  
    attr_accessor :test_user, :test_project, :roles
  
    def setup
      setup_data
    end
  
    def test_role_granted
      tu = Badges::TestUser.create(:username =>'tu')
      tp = Badges::TestProject.create(:name =>'tp')
    
      tp.role_granted(:foo, tu)
      assert_equal 1, tu.roles.size
      assert_equal 'foo', tu.roles.first.name

      tp.role_granted(:bar, tu)
      assert_equal 2, tu.roles.size
    end

    def test_role_revoked
      tu = Badges::TestUser.create(:username =>'tu')
      tp = Badges::TestProject.create(:name =>'tp')
    
      tp.role_granted(:foo, tu)
      assert_equal 1, tu.roles.size
    
      tp.role_revoked(:foo, tu)
      assert_equal 0, tu.roles.size
    end

    def test_accepts_privilege?
      assert @test_project.accepts_privilege?(:authenticated, @test_user)
      assert @test_project.accepts_privilege?(:authenticated, @test_user)
      assert @test_project.accepts_privilege?(:authenticated, @test_user)
      assert @test_project.accepts_privilege?(:authenticated, @test_user)
      assert !@test_project.accepts_privilege?(:other, @test_user)
    end
    
    def test_members_by_role
      mbr = @test_project.members_by_role
      assert mbr.keys.include?(@roles['member'])
      assert_equal @test_user, mbr[@roles['member']].first
      assert mbr.keys.include?(@roles['other'])
      assert_equal @other_user, mbr[@roles['other']].first
    end

    private
  
    def setup_data
      @test_user = Badges::TestUser.create(:username =>'tu')
      @other_user = Badges::TestUser.create(:username =>'otu')
      @test_project = Badges::TestProject.create(:name =>'tp')
      @other_project = Badges::TestProject.create(:name =>'otp')
      @roles = {}
      @privileges = {}
  
      ['authenticated','admin','member','manager','other'].each{|r| @roles[r] = Badges::Role.create(:name=>r)}
             
      @roles.each_value do |r|
        @privileges[r.name] = Badges::Privilege.create(:name=>"#{r.name}")      
        Badges::RolePrivilege.create(:role=>r, :privilege=>@privileges[r.name])
      end
  
      Badges::UserRole.create(:role=>@roles['authenticated'], :user=>@test_user)
      Badges::UserRole.create(:role=>@roles['admin'],         :user=>@test_user)
      Badges::UserRole.create(:role=>@roles['member'],        :user=>@test_user, :authorizable=>@test_project)
      Badges::UserRole.create(:role=>@roles['other'],         :user=>@test_user, :authorizable=>@other_project)
      Badges::UserRole.create(:role=>@roles['other'],         :user=>@other_user, :authorizable=>@test_project)
      Badges::UserRole.create(:role=>@roles['manager'],       :user=>@test_user, :authorizable_type=>Badges::TestProject.to_s)
  
    end

  end
end