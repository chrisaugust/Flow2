class MonthlyCategoryReview < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :monthly_review
end
