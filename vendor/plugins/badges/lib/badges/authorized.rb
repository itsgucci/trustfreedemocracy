module Badges
  module Authorized
    
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def badges_authorized_user

        # set the associations
        has_many :user_roles, :class_name=>'Badges::UserRole', :foreign_key=>'user_id'
        has_many :roles, :through=>:user_roles, :uniq=>true
        
        #point userrole to the correct user class
        Badges::UserRole.associate_user_class(self)

        # include the instance methods on the user record
        include Badges::Authorized::InstanceMethods

        #grant each new user the default role if one is defined
        after_create :grant_default_user_role

      end
    end

    module InstanceMethods

      def has_privilege?(privilege, authorizable=nil)
        add_if_missing(privilege)
        !privileges(authorizable).detect{|p| p.name == privilege.to_s}.nil?
      end
      
      def grant_role(role_symbol, authorizable=nil)
        role = Badges::Role.find( :first,:conditions=>{:name=>role_symbol.to_s})
        role = Role.create(:name=>role_symbol.to_s) if role.nil?

        if authorizable.nil?
          self.user_roles.create(:role=>role)
        elsif authorizable.is_a? Class
          self.user_roles.create(:role=>role, :authorizable_type=>authorizable.base_class.to_s)
        else
          self.user_roles.create(:role=>role, :authorizable=>authorizable)
        end
        self.reload
      end
      
      def revoke_role(role_symbol, authorizable=nil)
        user_role = find_user_role_by_name(role_symbol.to_s, authorizable)
        user_role.destroy if user_role
        self.reload
      end
      
      def has_role?(role_symbol, authorizable=nil)
        !find_user_role_by_name(role_symbol.to_s, authorizable).nil?
      end

      def roles_on(authorizable=nil)
        conditions = if authorizable.nil?
          ["badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type IS NULL AND badges_user_roles.authorizable_id IS NULL",
            self.id]
        elsif authorizable.is_a? Class
          ["badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id IS NULL",
            role_name, self.id, authorizable.to_s]
        else
          ["badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id = ?", 
            self.id, authorizable.class.base_class.to_s, authorizable.id]
        end
        Badges::Role.find( :all,
          :joins=>" LEFT JOIN badges_user_roles on badges_user_roles.role_id = badges_roles.id",
          :conditions=>conditions)
      end
      
      def authorizables(klass=nil)
        authorizables = user_roles.inject([]) do |auths, ur|
          auths << ur.authorizable unless (ur.authorizable.nil? || (!klass.nil? && !ur.authorizable.is_a?(klass)))
          auths
        end
        authorizables.uniq
      end
      
      def authorizables_by_role(klass, role_symbol)
        role = Badges::Role.find( :first,:conditions=>{:name=>role_symbol.to_s})
        authorizables = user_roles.inject([]) do |auths, ur|
          auths << ur.authorizable if (ur.authorizable.is_a?(klass) && ur.role == role)
          auths
        end
        authorizables.uniq
      end
      
      def privileges(authorizable=nil)
        conditions = if authorizable.nil?
          ["ur.user_id = ? AND ur.authorizable_type IS NULL AND ur.authorizable_id IS NULL", 
            self.id]
        elsif authorizable.is_a? Class
          ["ur.user_id = ? AND ur.authorizable_type = ? AND ur.authorizable_id IS NULL", 
            self.id, authorizable.to_s]
        else
          ["ur.user_id = ? AND ((ur.authorizable_type = ? AND (ur.authorizable_id = ? OR ur.authorizable_id IS NULL)) OR (ur.authorizable_type IS NULL AND ur.authorizable_id IS NULL))", 
            self.id, authorizable.class.base_class.to_s, authorizable.id]
        end
        
        Badges::Privilege.find( :all,  
          :joins=>" LEFT JOIN badges_role_privileges rp on rp.privilege_id = badges_privileges.id
                    LEFT JOIN badges_roles r on rp.role_id = r.id
                    LEFT JOIN badges_user_roles ur on ur.role_id = r.id",
          :conditions=>conditions)
      end
      
      private
      
      def find_user_role_by_name(role_name, authorizable=nil)
        conditions = if authorizable.nil?
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type IS NULL AND badges_user_roles.authorizable_id IS NULL",
            role_name, self.id]
        elsif authorizable.is_a? Class
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id IS NULL",
            role_name, self.id, authorizable.to_s]
        else
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id = ?", 
            role_name, self.id, authorizable.class.base_class.to_s, authorizable.id]
        end
        Badges::UserRole.find( :first,
          :joins=>" LEFT JOIN badges_roles on badges_user_roles.role_id = badges_roles.id",
          :conditions=>conditions)
      end
      
      def find_users_by_role(role_name, authorizable=nil)
        conditions = if authorizable.nil?
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type IS NULL AND badges_user_roles.authorizable_id IS NULL",
            role_name, self.id]
        elsif authorizable.is_a? Class
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id IS NULL",
            role_name, self.id, authorizable.to_s]
        else
          ["badges_roles.name = ? AND badges_user_roles.user_id = ? AND badges_user_roles.authorizable_type = ? AND badges_user_roles.authorizable_id = ?", 
            role_name, self.id, authorizable.class.base_class.to_s, authorizable.id]
        end
        Badges::UserRole.find( :all,
          :joins=>" LEFT JOIN badges_roles on badges_user_roles.role_id = badges_roles.id",
          :conditions=>conditions)
      end
      
      def add_if_missing(privilege)
        if Badges::Config.create_when_missing
          p = Badges::Privilege.find_by_name(privilege.to_s)
          if p.nil?
            Badges::Privilege.create(:name=>privilege.to_s)
          end
        end
      end
      
      def grant_default_user_role
        default_user_role = Badges::Role.find_by_name((Badges::Config.default_user_role || "").to_s)
        Badges::UserRole.create(:role=>default_user_role, :user=>self) if default_user_role
      end

    end

  end
end
