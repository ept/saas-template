class CreateTokens < ActiveRecord::Migration
  def self.up
    create_table :tokens do |t|
      t.string :type
      t.string :param
      t.string :code
      t.integer :max_uses, :default => 1
      t.integer :use_count, :default => 0
      t.date :expires
    end

    add_index :tokens, :code, :unique => true
  end

  def self.down
  end
end
