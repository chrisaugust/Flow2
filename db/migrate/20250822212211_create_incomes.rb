class CreateIncomes < ActiveRecord::Migration[7.1]
  def change
    create_table :incomes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source
      t.decimal :amount
      t.date :received_on
      t.boolean :is_work_income
      t.text :notes

      t.timestamps
    end
  end
end
