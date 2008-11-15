class ExternalizeCertification < ActiveRecord::Migration
  def self.up
    add_column :certifications, :external_source, :string
    add_column :certifications, :external_id, :string
  end

  def self.down
    remove_column :certifications, :external_source
    remove_column :certifications, :external_id
  end
end
