require 'badges/core'
require 'badges/config'
require 'badges/authorizable'
require 'badges/authorized'
require 'badges/model_authorization'
require 'badges/authorize_handler'
require 'badges/privilege'
require 'badges/role'
require 'badges/role_privilege'
require 'badges/user_role'

require 'extensions/routing'
require 'extensions/kernel'

require 'dispatcher' unless defined?(::Dispatcher)
::Dispatcher.to_prepare :badges do
    base = File.dirname(__FILE__)
    # Load these on every request (in dev mode)
    load "#{base}/badges/admin_helper.rb"
    load "#{base}/badges/admin_controller.rb"
end
