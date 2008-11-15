class AddSupporterCount < ActiveRecord::Migration
  def self.up
    add_column :articles, :support_count, :integer, :default => 0

    Article.reset_column_information
    Article.all.each do |a|
      Article.update_counters a.id, :support_count => a.supporters.length
    end
  end

  def self.down
    remove_column :articles, :support_count
  end
  
end
