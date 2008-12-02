class AddCommunityToRoll < ActiveRecord::Migration
  def self.up
    add_column :rolls, :community_id, :integer
  end

  def self.down
    remove_column :rolls, :community_id
  end
end
