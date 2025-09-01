class AddMonthlyReviewToMonthlyCategoryReviews < ActiveRecord::Migration[7.1]
  def change
    add_reference :monthly_category_reviews, :monthly_review, null: false, foreign_key: true
  end
end
