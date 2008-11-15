module Badges

  module AuthorizeHandler

    def self.included(base)
      base.extend(ClassMethods)
      if base.respond_to?(:helper_method)
        base.send :helper_method, :has_privilege?
        base.send :helper_method, :if_privilege
      end
    end
  
    module ClassMethods

      # privilege_required 'manage users'
      # privilege_required ['kick butt', 'chew bubblegum']
      # options:
      # :only => [:view, :create, :delete], :only => :delete
      # :except => [:view, :create, :delete], :except => :view
      # :user => :attribute, :user => :method
      # :on => ClassName, :on => :attribute, :on => :method, :on => object
      # :param=>:id (must be used with :on=> ClassName)
      # :redirect => true or false, controls if the default redirect on failure should be used (true is default)
      # :unauthorized_message => string, message given to user if authorization fails
      def privilege_required(privilege, options = {})
        before_filter (options||{}) { |c| c.send :privilege_required, privilege, options }
      end
    end

    protected

    # used in global controller before_filter declared in init.rb to make sure there is always a current_user attached to the thread
    def propogate_current_user
      Badges.thread_current_user = current_user
    end

    # takes all the same options as the class method above except for :only and :except
    # defaults to :redirect is true
    def privilege_required(privilege, options={})
      user = get_by_method_or_attribute(options[:user])
      authorizable = get_authorizable_object(options)

      privileges = privilege.is_a?(Array) ? privilege : [privilege]
      if (privileges.detect{|p| !has_privilege?(p, authorizable, user)}).nil?
        yield if block_given?
        true
      else
        options[:redirect] = true unless options.include?(:redirect)
        unless options[:redirect] == false
          # if they don't have permission, send them elsewhere
          flash[:notice] = options[:unauthorized_message] || Badges::Config.unauthorized_message
          if !Badges::Config.unauthorized_controller_method.blank? and respond_to?(Badges::Config.unauthorized_controller_method)
            send(Badges::Config.unauthorized_controller_method, options)
          else
            authorization_denied(options)
          end
        end
        false
      end
    end

    # default method to handle unauthorized requests
    # will redirect to Badges::Config.unauthorized_url
    def authorization_denied(options={})
      respond_to do |format|
        format.html do
          redirect_to Badges::Config.unauthorized_url
        end
        format.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render(:text => (options[:unauthorized_message] || Badges::Config.unauthorized_message), :status => '401 Unauthorized')
        end
      end
    end
    
    def has_privilege?(privilege, authorizable=nil, user=nil)
      user ||= (send(:current_user) if respond_to?(:current_user)) || nil
      return false if user.nil? || user == :false
      if authorizable && authorizable.respond_to?(:accepts_privilege?)
        authorizable.accepts_privilege?(privilege, user)
      else
        user.has_privilege?(privilege)
      end
    end
    
    # if_privilege "do action" do
    #   link_to "foo"
    # end
    def if_privilege(privilege, authorizable=nil, user=nil)
      return false unless current_user
      yield if block_given? && has_privilege?(privilege, authorizable, user)
    end

    private

    def get_authorizable_object(options)
      authorizable = nil
      if options.include?(:param)
        if options.include?(:on) && options[:on].is_a?(Class)
          authorizable = options[:on].send(:find, params[options[:param].to_s])
        else
          raise 'To use :param, you must include an :on option that specifies an AR class'
        end
      elsif options[:on].is_a?(Class)
        authorizable = options[:on]
      elsif options[:on].is_a?(Symbol)
        authorizable = get_by_method_or_attribute(options[:on])
      elsif options[:on].respond_to?(:accepts_privilege?)
        authorizable = options[:on]
      elsif options[:on]
        raise "Could not decipher the :on expression to determine a authorizable object."
      end
      authorizable
    end
    
    def get_by_method_or_attribute(name)
      result = nil
      if methods.include?(name.to_s)
        m = method(name)
        result = m.call unless m.nil?
      else
        variable_name = "@#{name.to_s}"
        if instance_variable_defined?(variable_name)
          result = instance_variable_get(variable_name)
        end
      end
      result
    end

  end
end