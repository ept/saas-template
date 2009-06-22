class AddDatabaseConstraints < ActiveRecord::Migration
  def self.up
    change_column :users, :is_admin, :boolean, :default => 0

    add_index :users, :email, :unique => true
    add_index :customers, :subdomain, :unique => true
    add_index :customer_users, [:customer_id, :user_id], :unique => true

    execute "ALTER TABLE customer_users ADD CONSTRAINT customer_users__customer_id FOREIGN KEY (customer_id) REFERENCES customers(id);"
    execute "ALTER TABLE customer_users ADD CONSTRAINT customer_users__user_id FOREIGN KEY (user_id) REFERENCES users(id);"

  end

  def self.down
  end
end
