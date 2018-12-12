class AddHideOptionsToFunctions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :functions, :hidden_on_overview, :boolean, :default => false
  end

  def self.down
    remove_column :functions, :hidden_on_overview
  end
end
