ActionController::Base.send :before_filter, :propogate_current_user

require 'badges'

ActionController::Base.send :include, Badges::AuthorizeHandler

# in edge rails 2.+, this adds the erb pages under the plugin to the view path
ActionController::Base.append_view_path(File.join( File.dirname(__FILE__), 'views'))

ActiveRecord::Base.send :include, Badges::Authorized, Badges::Authorizable, Badges::ModelAuthorization