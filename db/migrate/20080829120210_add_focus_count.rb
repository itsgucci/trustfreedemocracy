class AddFocusCount < ActiveRecord::Migration
  def self.up
    add_column :articles, :focus_count, :integer, :default => 0
    
    Article.reset_column_information
    Article.all.each do |a|
      Article.update_counters a.id, :focus_count => a.endorsements.active.length
    end
  end

  def self.down
    remove_column :articles, :focus_count
  end
end
