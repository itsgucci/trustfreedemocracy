class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :badges_privileges, :force => true do |t|
      t.column :name,               :string, :limit => 50
      t.column :name,               :string, :limit => 50
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    create_table :badges_role_privileges, :force => true  do |t|
      t.column :role_id,            :integer
      t.column :privilege_id,       :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    
  end

  def self.down
    drop_table :badges_role_privileges
    drop_table :badges_privileges
  end
end
