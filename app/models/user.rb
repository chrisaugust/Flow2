class User < ApplicationRecord
  has_secure_password

  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :monthly_reviews, dependent: :destroy
  has_many :monthly_category_reviews, through: :monthly_reviews

  validates :email, presence: true, uniqueness: true

  after_create :create_default_categories

  private

  def create_default_categories
    default_category_names = ["Housing", "Food", "Transportation", "Utilities", "Insurance", "Healthcare", "Savings", "Debt", "Personal", "Entertainment", "Taxes"]
    default_category_names.each do |name|
      categories.create!(name: name, is_default: true)
    end
  end
end
