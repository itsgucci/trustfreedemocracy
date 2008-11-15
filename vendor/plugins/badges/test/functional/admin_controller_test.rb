require File.dirname(__FILE__) + '/../test_helper'

# need to require this as it gets loaded dynamically
require 'badges/admin_controller'

# Re-raise errors caught by the controller.
module Badges

  class AdminController
    def current_user
      @current_user
    end

    def current_user=(user)
      @current_user = user
    end

    def rescue_action(e)
      raise e 
    end
  end

  class AdminControllerTest < Test::Unit::TestCase

    def setup
      @controller = Badges::AdminController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      setup_data
    end

    def test_index_should_list_roles_and_privileges
      get :index
      assert assigns(:privileges)
      assert assigns(:roles)
      assert assigns(:privilege_roles)
      assert assigns(:badges_role)
      assert assigns(:badges_privilege)
    end
    
    def test_update_role_privileges_no_changes
      options = ['authenticated','admin','member','manager'].inject({}) do |hash, r| 
        hash["p#{@test_privileges[r].id}_r#{@test_roles[r].id}"] = 1
        hash
      end

      assert_difference('Badges::RolePrivilege.count',0) do
        post :update_role_privileges, options
      end      
    end

    def test_update_role_privileges_delete_all
      assert_difference('Badges::RolePrivilege.count',-4) do
        post :update_role_privileges, {}
      end      
    end

    def test_update_role_privileges_add_four

      # add this new privilege to each role
      a4p = Badges::Privilege.create(:name=>"addfour")
      options = ['authenticated','admin','member','manager'].inject({}) do |hash, r| 
        hash["p#{@test_privileges[r].id}_r#{@test_roles[r].id}"] = 1
        hash["p#{a4p.id}_r#{@test_roles[r].id}"] = 1
        hash
      end
      

      assert_difference('Badges::RolePrivilege.count',4) do
        post :update_role_privileges, options
      end      
    end

    def test_create_role
      assert_difference('Badges::Role.count') do
        post :create_role, :badges_role=>{:name=>'foobar'}
      end
    end

    def test_delete_role
      delete_role = @test_roles['member']
      assert_difference('Badges::Role.count', -1) do
        get :delete_role, :id=>delete_role
      end
    end

    def test_create_privilege
      assert_difference('Badges::Privilege.count', 1) do
        post :create_privilege, :badges_privilege=>{:name=>'foobar'}
      end
    end

    def test_delete_privilege
      delete_privilege = @test_privileges['member']
      assert_difference('Badges::Privilege.count', -1) do
        get :delete_privilege, :id=>delete_privilege
      end
    end

    protected
    
    def setup_data
      @test_roles = {}
      @test_privileges = {}

      ['authenticated','admin','member','manager'].each{|r| @test_roles[r] = Badges::Role.create(:name=>r)}

      @test_roles.each_value do |r|
        @test_privileges[r.name] = Badges::Privilege.create(:name=>"#{r.name}")
        Badges::RolePrivilege.create(:role=>r, :privilege=>@test_privileges[r.name])
      end

      # Badges::Role.find(:all).each{|r| puts r.inspect; puts r.privileges.inspect; puts ""}

    end

  end
end