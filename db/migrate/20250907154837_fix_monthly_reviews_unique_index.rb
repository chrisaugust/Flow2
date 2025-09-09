class FixMonthlyReviewsUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    # Remove old single-column index if it exists
    remove_index :monthly_reviews, :month_code if index_exists?(:monthly_reviews, :month_code)

    # Add new unique index only if it doesn't already exist
    add_index :monthly_reviews, [:user_id, :month_code], unique: true, name: 'index_monthly_reviews_on_user_id_and_month_code' unless index_exists?(:monthly_reviews, [:user_id, :month_code], name: 'index_monthly_reviews_on_user_id_and_month_code')
  end
end
