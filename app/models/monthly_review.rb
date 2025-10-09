class MonthlyReview < ApplicationRecord
  belongs_to :user
  has_many :monthly_category_reviews, dependent: :destroy

  validates :month_code, presence: true, uniqueness: { scope: :user_id }

  before_validation :set_month_code, on: :create

  private

  def set_month_code
    self.month_code ||= month_start.strftime('%m%Y') if month_start.present?
  end
end

