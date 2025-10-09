class Category < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy
  has_many :monthly_category_reviews
end
