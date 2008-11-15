class AddFacebookIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :facebook_id, :string, :length => 64
  end

  def self.down
    remove_column :users, :facebook_id
  end
end
