class CreateBankrolls < ActiveRecord::Migration[5.1]
  def change
    create_table :bankrolls do |t|
      t.float :amount
      t.float :risk
      t.integer :user_id, foreign_key: true
      
      t.timestamps
    end
  end
end
