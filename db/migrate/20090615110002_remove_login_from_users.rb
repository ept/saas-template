class RemoveLoginFromUsers < ActiveRecord::Migration
  def self.up
    remove_index :users, :login
    remove_column :users, :login
  end

  def self.down
  end
end
