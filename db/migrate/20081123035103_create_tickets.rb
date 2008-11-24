class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.decimal :worth
      t.integer :community_id
      t.string :transaction_id
      t.text :amazon_response
      t.string :currency, :default => "leaf"
      t.decimal :amount
      t.string :fee_currency, :default => "USD"
      t.decimal :fee_amount
      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
