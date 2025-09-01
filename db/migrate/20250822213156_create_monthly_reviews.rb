class CreateMonthlyReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :monthly_reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month_start
      t.decimal :total_income
      t.decimal :total_expenses
      t.decimal :total_life_energy_hours
      t.boolean :completed
      t.text :notes

      t.timestamps
    end
  end
end
