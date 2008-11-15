module Badges
  module Authorizable
    
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      def badges_authorizable_object
        has_many :user_roles, :as=>:authorizable, :class_name=>"Badges::UserRole"
        include Badges::Authorizable::InstanceMethods

        singleton_class.class_eval do
          define_method("accepts_privilege?") do |privilege, user|
            user.has_privilege?(privilege, self)        
          end
        end
      end

    end

    module InstanceMethods

      def accepts_privilege?(privilege, user)
        user.has_privilege?(privilege, self)        
      end
      
      def role_granted(role_name, user)
        user.grant_role(role_name, self)
      end
      
      def role_revoked(role_name, user)
        user.revoke_role(role_name, self)
      end
      
      def members_by_role
        user_roles.inject({}) do |groups, ur|
          if groups[ur.role].nil?
            groups[ur.role] = [ur.user]
          else 
            groups[ur.role] << ur.user
          end
          groups 
          end
      end
      
      def members
        user_roles.collect{ |ur| ur.user }.uniq
      end
      
    end
  end
end

