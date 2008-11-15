module Badges
  class RolePrivilege < ActiveRecord::Base
    set_table_name "badges_role_privileges"
    
    belongs_to :role, :class_name=>'Badges::Role'
    belongs_to :privilege, :class_name=>'Badges::Privilege'
    validates_uniqueness_of :privilege_id, :scope=>:role_id

  end
end