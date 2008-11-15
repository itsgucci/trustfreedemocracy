require File.dirname(__FILE__) + '/../test_helper'

class AuthorizeHelperTest < Test::Unit::TestCase
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ApplicationHelper
  include Badges::AuthorizeHandler  
  
  def current_user
    @current_user
  end

  def current_user=(user)
    @current_user = user
  end

  def test_has_privilege_failure
    assert !has_privilege?('test', nil)
    assert !has_privilege?('test', Badges::TestUser.new(:username=>'what'))
  end

  def test_has_privilege_success
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'tester')
    p = Badges::Privilege.create(:name=>'test')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)

    assert !has_privilege?('test', nil, tu)
    tu.grant_role :tester

    assert has_privilege?('test', nil, tu)
    @current_user = tu
    assert has_privilege?('test')
  end
  
  def test_if_privilege_failure
    
    result = true
    if_privilege('test') do
      result = false
    end
    assert result, "result should not be set to false"
  end

  def test_if_privilege_success
    tu = Badges::TestUser.create(:username =>'tu')
    r = Badges::Role.create(:name=>'tester')
    p = Badges::Privilege.create(:name=>'test')
    rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)

    assert !has_privilege?('test', tu)
    tu.grant_role :tester

    result = false
    if_privilege('test', nil, tu) do
      result = true
    end
    assert result, "result should not be set to false"

    @current_user = tu
    result = false
    if_privilege('test') do
      result = true
    end
    assert result, "result should not be set to false"

  end

end
