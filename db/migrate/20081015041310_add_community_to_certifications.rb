class AddCommunityToCertifications < ActiveRecord::Migration
  def self.up
    add_column :certifications, :community_id, :integer
  end

  def self.down
    remove_column :certifications, :community_id
  end
end
