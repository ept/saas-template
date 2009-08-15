class AddMarketingOptInToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :marketing_opt_in, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :users, :marketing_opt_in
  end
end
