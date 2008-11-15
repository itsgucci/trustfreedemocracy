class CreateRolls < ActiveRecord::Migration
  def self.up
    create_table :rolls do |t|
      t.integer :article_id
      t.string :tom_id
      t.string :number
      t.string :house
      t.string :session
      t.string :kind
      t.string :question
      t.string :required
      t.string :result
      t.integer :aye_count, :default => 0
      t.integer :nay_count, :default => 0
      t.integer :present_count, :default => 0
      t.integer :novote_count, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :rolls
  end
end
