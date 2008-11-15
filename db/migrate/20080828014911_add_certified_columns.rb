class AddCertifiedColumns < ActiveRecord::Migration
  def self.up
    add_column :articles_supporters, :certified, :boolean, :default => false
    remove_column :comments, :certified
    add_column :comments, :certified, :boolean, :default => false
    add_column :endorsements, :certified, :boolean, :default => false
  end

  def self.down
    remove_column :articles_supporters, :certified
    remove_column :comments, :certified
    remove_column :endorsements, :certified
  end
end
