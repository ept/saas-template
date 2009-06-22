class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.integer :customer_id
      t.string :name
      t.timestamps
    end

    add_column :test_scripts, :project_id, :integer
    remove_column :test_scripts, :customer_id 

  end

  def self.down
    drop_table :projects
  end
end
