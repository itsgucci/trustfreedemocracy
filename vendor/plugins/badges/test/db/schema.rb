ActiveRecord::Schema.define(:version => 0) do

  create_table :badges_test_users, :force => true do |t|
    t.column :username, :string
  end

  create_table :badges_test_projects, :force => true do |t|
    t.column :name, :string
  end

end