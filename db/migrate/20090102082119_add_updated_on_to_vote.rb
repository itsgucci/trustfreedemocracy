class AddUpdatedOnToVote < ActiveRecord::Migration
  def self.up
    add_column :votes, :updated_on, :datetime
  end

  def self.down
    remove_column :votes, :updated_on
  end
end
