class FixMonthlyReviewsUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :monthly_reviews, :month_code if index_exists?(:monthly_reviews, :month_code)

    add_index :monthly_reviews, [:user_id, :month_code], unique: true
  end
end
