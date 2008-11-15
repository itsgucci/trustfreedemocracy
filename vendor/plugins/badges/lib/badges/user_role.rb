module Badges
  class UserRole < ActiveRecord::Base
    set_table_name "badges_user_roles"

    belongs_to :authorizable, :polymorphic => true
    belongs_to :role, :class_name=>"Badges::Role", :foreign_key=>'role_id'

    class <<self
      def associate_user_class(user_class)
        belongs_to :user, :class_name=>user_class.to_s, :foreign_key=>'user_id'
      end
    end
    
  end
end