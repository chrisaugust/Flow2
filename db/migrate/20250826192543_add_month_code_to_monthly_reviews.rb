class AddMonthCodeToMonthlyReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :monthly_reviews, :month_code, :string
    add_index :monthly_reviews, :month_code, unique: true
  end
end
