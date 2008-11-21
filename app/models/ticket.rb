class Ticket < ActiveRecord::Base
  
  belongs_to :user
  
  def self.assets
    sum(:amount)
  end
  def self.liabilities
    sum(:fee_amount)
  end
  def self.reserve
    assets - liabilities
  end
  
end
