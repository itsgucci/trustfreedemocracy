class AddTopPriorityToDistrict < ActiveRecord::Migration
  def self.up
    add_column :districts, :top_priority, :integer, :null => true
    
    District.reset_column_information
    
    District.all.each do |district|
      district.update_attribute 'top_priority', district.top_priority
    end
    
  end

  def self.down
    remove_column :districts, :top_priority
  end
end
