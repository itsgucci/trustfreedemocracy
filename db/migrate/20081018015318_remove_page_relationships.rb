class RemovePageRelationships < ActiveRecord::Migration
  def self.up
    # make page polymorphic
    add_column :pages, :pageable_type, :string
    add_column :pages, :pageable_id, :integer
    Page.reset_column_information
    # update page with page relationship
    Page.all.each do |page|
      rel = page.page_relationships.first
      page.pageable_type = rel.pagable_type
      page.pageable_id = rel.pagable_id
      page.save
    end
    # remove page relationship
    drop_table :page_relationships
    
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
