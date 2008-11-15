class AddSession < ActiveRecord::Migration
  def self.up
    add_column :articles, :session, :integer, :default => 0
    add_column :communities, :session, :integer, :default => 1
    
  end

  def self.down
    remove_column :articles, :session
    remove_column :communities, :session
  end
end
