class CreateRollVotes < ActiveRecord::Migration
  def self.up
    create_table :roll_votes do |t|
      t.integer :roll_id
      t.integer :user_id
      t.integer :district_id
      t.integer :community_id
      t.integer :vote, :null => true
      t.timestamps
    end
  end

  def self.down
    drop_table :roll_votes
  end
end
