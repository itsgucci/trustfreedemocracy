class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table :bookmarks do |t|
      t.integer :user_id, :null => false
      t.string :object_type, :null => false
      t.integer :object_id, :null => false
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :bookmarks
  end
end
