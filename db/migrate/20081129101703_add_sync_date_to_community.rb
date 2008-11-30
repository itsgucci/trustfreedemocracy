class AddSyncDateToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :sync_date, :datetime
  end

  def self.down
    remove_column :communities, :sync_date
  end
end
