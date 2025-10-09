class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :monthly_reviews, dependent: :destroy
  has_many :monthly_category_reviews, through: :monthly_reviews

  validates :email, presence: true, uniqueness: true
  validates :hourly_wage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_create :create_default_categories

  private

  def create_default_categories
    default_category_names = ["Housing", "Food", "Transportation", "Utilities", "Insurance", 
                              "Healthcare", "Savings", "Debt", "Personal", "Entertainment", "Taxes"]
    default_category_names.each do |name|
      categories.create!(name: name, is_default: true)
    end
  end
end