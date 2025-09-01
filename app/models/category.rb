class Category < ApplicationRecord
  belongs_to :user
  has_many :expenses
  has_many :monthly_category_reviews
end
