require File.dirname(__FILE__) + '/../test_helper'

module Badges
  class SomeUser < ActiveRecord::Base
    set_table_name "badges_test_users"    
  end

  class AnotherUser < ActiveRecord::Base
    set_table_name "badges_test_users"    
  end

  class UserRoleTest < Test::Unit::TestCase
  
    def test_associate_user_class
      Badges::UserRole.associate_user_class(Badges::SomeUser)
      assert Badges::UserRole.new.respond_to?(:user)    

      assert_nothing_raised(ActiveRecord::AssociationTypeMismatch) do
        ur = Badges::UserRole.new
        ur.user = Badges::SomeUser.new
      end

      assert_raises(ActiveRecord::AssociationTypeMismatch) do
        ur = Badges::UserRole.new
        ur.user = Badges::AnotherUser.new
      end
    end

  end

end
