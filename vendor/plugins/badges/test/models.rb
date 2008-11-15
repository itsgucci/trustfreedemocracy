module Badges

  class TestUser < ActiveRecord::Base
    set_table_name "badges_test_users"    

    badges_authorized_user
  end

  class TestProject < ActiveRecord::Base
    set_table_name "badges_test_projects"

    badges_authorizable_object
  end

end