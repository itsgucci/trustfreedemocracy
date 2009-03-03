class AddCurrentSessionToCommunity < ActiveRecord::Migration
  def self.up
    add_column :communities, :current_session, :integer
  end

  def self.down
    remove_column :communities, :current_session
  end
end
