class CreateCustomerAddresses < ActiveRecord::Migration
  def self.up
    create_table :customer_addresses do |t|
      t.references :customer
      t.string :name, :limit => 100
      t.string :contact_name, :limit => 100
      t.string :address, :limit => 250
      t.string :city, :limit => 100
      t.string :state, :limit => 100
      t.string :postal_code, :limit => 50
      t.string :country, :limit => 100
      t.string :country_code, :limit => 10
      t.string :tax_number, :limit => 50
      t.timestamps
    end
  end 

  def self.down
    drop_table :customer_addresses
  end
end
