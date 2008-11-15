require File.dirname(__FILE__) + '/../test_helper'

class TestAuthorizeHandlerController < ActionController::Base

  def current_user
    @current_user || Badges::TestUser.new(:username=>'what')
  end

  def current_user=(user)
    @current_user = user
  end
  
  privilege_required ['can test','really can test'], :only => [:index]
  privilege_required 'can test class', :on=>Badges::TestProject, :only => [:get_class]
  privilege_required 'can test param', :on=>Badges::TestProject, :param=>:id, :only => [:get_param]

  @test_project = nil

  def get_test_project
    @test_project
  end

  def test_project=(tp)
    @test_project = tp
  end

  def index
    render :text=>"allowed"
  end

  def get_class
    render :text=>"class"
  end

  def get_param
    render :text=>"param"
  end

  def get_variable
    privilege_required 'can test variable', :on=>:test_project do
      render :text=>"variable"
    end
  end

  def get_method
    privilege_required 'can test method', :on=>:get_test_project do
      render :text=>"method"
    end
  end

  def get_object
    aproject = get_test_project
    privilege_required 'can test object', :on=>aproject do
      render :text=>"object"
    end
  end


  def rescue_action(e) 
    raise e 
  end

end

class AuthorizeHandlerTest < Test::Unit::TestCase
    
  def setup
    @controller = TestAuthorizeHandlerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # basic test of making the check fail
  def test_privilege_required_failure
    tu = Badges::TestUser.create(:username =>'tu')
    tu.grant_role :admin
    assert !tu.has_privilege?('can test')

    @controller.current_user = tu
    get :index

    assert_not_equal "allowed", @response.body
    assert_response :redirect
    assert_redirected_to "/session/new"
    assert_nil assigns(:foo)
  end

  def test_privilege_required_success
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'tester')
    p1 = Badges::Privilege.create(:name=>'can test')
    p2 = Badges::Privilege.create(:name=>'really can test')
    rp1 = Badges::RolePrivilege.create(:role=>r, :privilege=>p1)
    rp2 = Badges::RolePrivilege.create(:role=>r, :privilege=>p2)
    tu.grant_role :tester
    assert tu.has_privilege?('can test')
    assert tu.has_privilege?('really can test')

    @controller.current_user = tu
    get :index

    assert_equal "allowed", @response.body
  end
  
  def test_privilege_required_authorizable_class
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'class tester')
    p = Badges::Privilege.create(:name=>'can test class')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)

    @controller.current_user = tu
    get :get_class
    assert_not_equal "class", @response.body
    assert_response :redirect

    # once we grant the role, now this should work
    tu.grant_role 'class tester', Badges::TestProject
    
    get :get_class
    assert_equal "class", @response.body
    assert_response :success
  end
  
  def test_privilege_required_authorizable_param
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'param tester')
    p = Badges::Privilege.create(:name=>'can test param')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
    tp = Badges::TestProject.create(:name=>'test authorizable param')

    @controller.current_user = tu
    get :get_param, :id=>tp.id
    assert_not_equal "param", @response.body
    assert_response :redirect

    # once we grant the role, now this should work
    tu.grant_role 'param tester', tp
    assert tp.accepts_privilege?('can test param', tu)
    
    get :get_param, :id=>tp.id
    assert_equal "param", @response.body
    assert_response :success
  end
  
  def test_privilege_required_authorizable_variable
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'variable tester')
    p = Badges::Privilege.create(:name=>'can test variable')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
    tp = Badges::TestProject.create(:name=>'test authorizable variable')

    @controller.current_user = tu
    @controller.test_project = tp
    get :get_variable
    assert_not_equal "variable", @response.body
    assert_response :redirect

    # once we grant the role, now this should work
    tu.grant_role 'variable tester', tp
    assert tp.accepts_privilege?('can test variable', tu)
    
    get :get_variable
    assert_equal "variable", @response.body
    assert_response :success
  end

  def test_privilege_required_authorizable_method
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'method tester')
    p = Badges::Privilege.create(:name=>'can test method')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
    tp = Badges::TestProject.create(:name=>'test authorizable method')

    @controller.current_user = tu
    @controller.test_project = tp
    get :get_method
    assert_not_equal "method", @response.body
    assert_response :redirect

    # once we grant the role, now this should work
    tu.grant_role 'method tester', tp
    assert tp.accepts_privilege?('can test method', tu)
    
    get :get_method
    assert_equal "method", @response.body
    assert_response :success
  end

  def test_privilege_required_authorizable_object
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'object tester')
    p = Badges::Privilege.create(:name=>'can test object')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
    tp = Badges::TestProject.create(:name=>'test authorizable object')

    @controller.current_user = tu
    @controller.test_project = tp
    get :get_object
    assert_not_equal "object", @response.body
    assert_response :redirect

    # once we grant the role, now this should work
    tu.grant_role 'object tester', tp
    assert tp.accepts_privilege?('can test object', tu)
    
    get :get_object
    assert_equal "object", @response.body
    assert_response :success
  end

end
