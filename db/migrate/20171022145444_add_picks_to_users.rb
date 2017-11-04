class AddPicksToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :picks, :jsonb, null: false, default: '{}'
  end
end
