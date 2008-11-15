class AddCommunityIdToActions < ActiveRecord::Migration
  def self.up
    add_column :actions, :community_id, :integer
  end

  def self.down
    remove_column :actions, :community_id
  end
end
