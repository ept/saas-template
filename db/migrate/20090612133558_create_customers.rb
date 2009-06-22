class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.string :subdomain
      t.string :name
      t.timestamps
    end

    create_table :customer_users do |t|
      t.integer :customer_id
      t.integer :user_id
      t.integer :permissions
    end
  end

  def self.down
    drop_table :customers
    drop_table :customer_users
  end
end
