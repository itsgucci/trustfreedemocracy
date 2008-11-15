require File.dirname(__FILE__) + '/../test_helper'

module Badges
  class RoleTest < Test::Unit::TestCase

    def test_privileges
      r = Badges::Role.create(:name=>'tester')
      p = Badges::Privilege.create(:name=>'can test')
      rp = Badges::RolePrivilege.create(:role=>r, :privilege=>p)
      assert_equal 'tester', r.name
      assert_equal 'can test', p.name
      assert_equal rp, r.role_privileges.first
      assert_equal p, r.privileges.first
    end

  end
end