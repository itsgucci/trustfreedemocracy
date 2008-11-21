class AddCostPerHourToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :cost_per_hour, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :articles, :cost_per_hour
  end
end
