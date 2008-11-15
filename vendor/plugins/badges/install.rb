RAILS_ROOT=File.expand_path(File.join(File.dirname(__FILE__), '..','..','..'))

load "#{File.dirname(__FILE__)}/install_manager.rb"

Badges::InstallManager.install
