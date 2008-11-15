require File.dirname(__FILE__) + '/../test_helper'

module Badges
  class PrivilegeTest < Test::Unit::TestCase

    def test_add_new_privilege_to_admin_role
      Badges::Role.create(:name=>Badges::Config.default_admin_role.to_s)
      p = Badges::Privilege.create(:name=>'can test')
      r = Badges::Role.find_by_name(Badges::Config.default_admin_role.to_s)
      assert r.privileges.include?(p)
    end
  end
end