module Badges

  class AdminController < ActionController::Base
    layout 'badges/admin'
	
	before_filter :check_authorization
	
	def	check_authorization
	  user = User.find(session[:user]) if session[:user]
	  unless user && user.has_privilege('manage badges')
	    flash[:error] = "You must be this high to ride"
	  end
	end

    # display the list of all roles and permissions
    def index
      @roles = Badges::Role.find(:all)
      @privileges = Badges::Privilege.find(:all)
      @privilege_roles = {}
      @privileges.each { |p| @privilege_roles[p.id] = p.roles.inject({}) { |hash, r| hash[r.id] = r.id; hash } }
      # for creating a new role
      @badges_role = Badges::Role.new
      @badges_privilege = Badges::Privilege.new
    end
    
    def users
      @roles = Badges::Role.find(:all)
      @users = User.find(:all)
      @user_roles = {}
      @users.each { |u| @user_roles[u.id] = u.roles.inject({}) { |hash, r| hash[r.id] = r.id; hash } }
      # for creating a new role
      @badges_role = Badges::Role.new
      @badges_privilege = Badges::Privilege.new
    end
    
    def update_role_privileges
      @roles = Badges::Role.find(:all)
      @privileges = Badges::Privilege.find(:all)

      @roles.each do |r|
        @privileges.each do |p|
          k = "p#{p.id}_r#{r.id}"
          # puts "checking for key #{k}"
          # puts r.privileges.inspect

          if r.privileges.include?(p) && !params.has_key?(k)
            # puts "gonna do a delete #{k}"
            role_privileges = Badges::RolePrivilege.find(:all, :conditions=>['role_id = ? and privilege_id = ?', r.id, p.id])
            role_privileges.each{|rp| rp.destroy}
          elsif !r.privileges.include?(p) && params.has_key?(k)
            # puts "gonna do an insert for #{k}"
            Badges::RolePrivilege.create(:role=>r,:privilege=>p)
          end
        end
      end
      flash[:notice] = "Changes saved"

      redirect_to :controller=>self.controller_name, :action=>'index'
    end

    def create_role
      @badges_role = Badges::Role.new(params[:badges_role])
      if @badges_role.save
        flash[:notice] = "Created role '#{@badges_role.name}'"
      end  
      redirect_to :controller=>self.controller_name, :action=>'index'
    end
    
    def delete_role
      @badges_role = Badges::Role.find(params[:id])
      @badges_role.destroy
      flash[:notice] = "Deleted role '#{@badges_role.name}'"
      redirect_to :controller=>self.controller_name, :action=>'index'
    end

    def create_privilege
      @badges_privilege = Badges::Privilege.new(params[:badges_privilege])
      if @badges_privilege.save
        flash[:notice] = "Created privilege '#{@badges_privilege.name}'"
      end  
      redirect_to :controller=>self.controller_name, :action=>'index'
    end
    
    def delete_privilege
      @badges_privilege = Badges::Privilege.find(params[:id])
      @badges_privilege.destroy
      flash[:notice] = "Deleted privilege '#{@badges_privilege.name}'"
      redirect_to :controller=>self.controller_name, :action=>'index'
    end
    
    # add the included authentication module, if there is one
    mod = Badges::Config.authentication_include
    unless mod.nil?
      if mod.is_a? String
        include mod.constantize
      elsif mod.is_a? Symbol
        include mod.to_s.classify.constantize
      else
        include mod
      end
    end

  end
end
