class ChangeCertDistToNil < ActiveRecord::Migration
  def self.up
    change_column :certifications, :district_id, :integer, :null => true
  end

  def self.down
  end
end
