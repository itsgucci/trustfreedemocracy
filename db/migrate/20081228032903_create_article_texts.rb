class CreateArticleTexts < ActiveRecord::Migration
  def self.up
    create_table :article_texts, :force => true do |t|
      t.integer :article_id
      t.string :version, :default => "DU"
      t.text :text
      t.timestamps
    end
    add_column :articles, :article_text_id, :integer
    Article.reset_column_information
    Article.all.each do |article|
      article.article_text = article.article_texts.create( :text => article.text )
      article.save
    end
    remove_column :articles, :text
  end

  def self.down
    add_column :articles, :text, :text
    Article.reset_column_information
    Article.all.each do |article|
      article.write_attribute('text', article.text)
      article.save
    end
    remove_column :articles, :article_text_id    
    drop_table :article_texts
  end
end
