class AddVisibleToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :visible, :bool, :default => true
  end

  def self.down
    remove_column :communities, :visible
  end
end
