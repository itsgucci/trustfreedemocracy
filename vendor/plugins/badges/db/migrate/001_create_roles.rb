class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :badges_roles, :force => true do |t|
      t.column :name,               :string, :limit => 50
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    create_table :badges_user_roles, :force => true  do |t|
      t.column :user_id,            :integer
      t.column :role_id,            :integer
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
  end

  def self.down
    drop_table :badges_roles
    drop_table :badges_user_roles
  end
end
