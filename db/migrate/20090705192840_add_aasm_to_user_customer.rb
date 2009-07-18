class AddAasmToUserCustomer < ActiveRecord::Migration
  def self.up
    add_column :customer_users, :state, :string, :nil => false
  end

  def self.down
    remove_column :customer_users, :state
  end
end
