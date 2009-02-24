class AddProfilePicToUser < ActiveRecord::Migration
  def self.up
      add_column :users, :profile_pic_file_name, :string # Original filename
      add_column :users, :profile_pic_content_type, :string # Mime type
      add_column :users, :profile_pic_file_size, :integer # File size in bytes
    end

    def self.down
      remove_column :users, :profile_pic_file_name
      remove_column :users, :profile_pic_content_type
      remove_column :users, :profile_pic_file_size
    end
end
