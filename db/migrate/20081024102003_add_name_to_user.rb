class AddNameToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :name, :string
    
    User.reset_column_information
    
    User.all.each do |user|
      user.update_attribute('name', user.first_name + " " + user.last_name)
    end
    
    remove_column :users, :first_name
    remove_column :users, :last_name
  end

  def self.down
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    
    User.reset_column_information
    
    User.all.each do |user|
      user.first_name = user.name
      user.save
    end
    
    remove_column :users, :name
  end
end
