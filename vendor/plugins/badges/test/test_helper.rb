$:.unshift(File.dirname(__FILE__) + '/../lib')

ENV["RAILS_ENV"] = "test"

require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test_help'
require 'rubygems'
require 'active_support/breakpoint'
require 'active_record/fixtures'

# load up the test db schema and model
require (File.dirname(__FILE__) + "/db/schema.rb")
require (File.dirname(__FILE__) + "/models.rb")

class Test::Unit::TestCase

  Badges::Config.default_admin_role = nil
  Badges::Config.default_user_role = nil
  Badges::Config.create_when_missing = false

  self.fixture_path = File.expand_path( File.join(File.dirname(__FILE__), 'fixtures') )
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  fixtures :badges_roles
  fixtures :badges_test_users
  fixtures :badges_user_roles
  fixtures :badges_role_privileges
  fixtures :badges_roles


end
