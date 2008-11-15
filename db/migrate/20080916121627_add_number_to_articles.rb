class AddNumberToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :number, :string
  end

  def self.down
    remove_column :articles, :number
  end
end
