class CreateApiUsers < ActiveRecord::Migration
  def self.up
    create_table :api_users do |t|
      t.string :login
      t.string :password
      t.timestamps
    end
  end

  def self.down
    drop_table :api_users
  end
end
