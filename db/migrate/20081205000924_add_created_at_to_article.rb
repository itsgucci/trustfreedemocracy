class AddCreatedAtToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :created_at, :datetime
    
    Article.reset_column_information
    Article.all.each {|article| article.update_attribute('created_at', article.updated_at)}
  end

  def self.down
    remove_column :articles, :created_at
  end
end
