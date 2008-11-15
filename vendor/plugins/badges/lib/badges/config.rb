module Badges
  class Config
    cattr_accessor :unauthorized_message, 
                   :unauthorized_controller_method, 
                   :unauthorized_url, 
                   :create_when_missing, 
                   :default_user_role,
                   :default_admin_role,
                   :authentication_include

    # unauthorized_message - message set in the flash if authorization fails
    @@unauthorized_message = "You are not authorized."

    # unauthorized_controller_method - method on the controller to call is authorization fails
    #  default is :access_denied, the method acts_as_authenticated and restful_authentication both call
    @@unauthorized_controller_method = :access_denied

    # unauthorized_url - if unauthorized_controller_method method not found, will forward to this url
    @@unauthorized_url = { :controller => '/sessions', :action => 'new' }
    
    # create_when_missing - create roles and privileges if they are checked but are missing
    @@create_when_missing = true

    # default_user_role - default role to grant to all new users when they are created, can be taken away after
    @@default_user_role = :authenticated

    # default_admin_role - default role to have all privileges: gets each privilege on create, can be taken away
    @@default_admin_role = :admin

    # authentication_include - name of mixin to include in the badges admin controller (e.g. AuthenticatedSystem for restful_authentication) 
    @@authentication_include = nil

    class <<self
      def define
        yield self
      end
    end

  end
end
